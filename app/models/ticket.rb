# frozen_string_literal: true

class Ticket < ApplicationRecord
  include AASM
  include AuditableHistory

  TICKET_NUMBER_ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
  TICKET_NUMBER_LENGTH = 8
  TICKET_NUMBER_MAX_RETRIES = 5

  audited

  belongs_to :customer
  belongs_to :assigned_agent, class_name: "Agent", optional: true
  has_many :comments, dependent: :destroy
  has_many_attached :attachments

  validates :subject, presence: true
  validates :description, presence: true
  validates :ticket_number, presence: true, uniqueness: true
  validate :acceptable_attachments

  # Scopes
  scope :active, -> { where(status: %w[agent_assigned in_progress hold]) }
  scope :open, -> { where.not(status: "closed") }
  scope :closed, -> { where(status: "closed") }

  before_validation :ensure_ticket_number, on: :create
  around_create :retry_on_ticket_number_collision

  after_create_commit :assign_agent_async

  # State machine
  aasm column: :status, whiny_transitions: true do
    state :new, initial: true
    state :agent_assigned
    state :in_progress
    state :hold
    state :closed

    event :assign_agent do
      transitions from: :new, to: :agent_assigned
    end

    event :start_progress do
      transitions from: [:agent_assigned, :hold], to: :in_progress
    end

    event :put_on_hold do
      transitions from: :in_progress, to: :hold
    end

    event :resume do
      transitions from: :hold, to: :in_progress
    end

    event :close do
      transitions from: [:agent_assigned, :in_progress, :hold], to: :closed
    end
  end

  # Status history from audits
  def status_changes
    audits
      .where("audited_changes ? 'status'")
      .order(:created_at)
      .map do |audit|
        changes = audit.audited_changes["status"]
        {
          from: changes.is_a?(Array) ? changes[0] : nil,
          to: changes.is_a?(Array) ? changes[1] : changes,
          changed_at: audit.created_at,
          changed_by: audit.user
        }
      end
  end

  # Get closed_at timestamp from audits
  def closed_at
    audits
      .where("audited_changes -> 'status' ->> 1 = ?", "closed")
      .order(:created_at)
      .last&.created_at
  end

  private

  def ensure_ticket_number
    return if ticket_number.present?

    self.ticket_number = self.class.generate_ticket_number
  end

  def retry_on_ticket_number_collision
    attempts = 0

    begin
      yield
    rescue ActiveRecord::RecordNotUnique => e
      raise if attempts >= TICKET_NUMBER_MAX_RETRIES
      raise unless e.message.include?("ticket_number") || e.message.include?("index_tickets_on_ticket_number")

      attempts += 1
      self.ticket_number = nil
      ensure_ticket_number
      retry
    end
  end

  def self.generate_ticket_number
    Array.new(TICKET_NUMBER_LENGTH) do
      TICKET_NUMBER_ALPHABET[SecureRandom.random_number(TICKET_NUMBER_ALPHABET.length)]
    end.join
  end

  def assign_agent_async
    TicketAssignmentJob.perform_later(id)
  end

  ALLOWED_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/gif
    image/webp
    application/pdf
  ].freeze

  MAX_ATTACHMENT_SIZE = 10.megabytes

  def acceptable_attachments
    return unless attachments.attached?

    attachments.each do |attachment|
      unless ALLOWED_CONTENT_TYPES.include?(attachment.content_type)
        errors.add(:attachments, "must be an image (JPEG, PNG, GIF, WebP) or PDF")
      end

      if attachment.byte_size > MAX_ATTACHMENT_SIZE
        errors.add(:attachments, "must be less than 10MB")
      end
    end
  end
end
