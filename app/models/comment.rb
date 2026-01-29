# frozen_string_literal: true

class Comment < ApplicationRecord
  audited associated_with: :ticket

  belongs_to :ticket, counter_cache: true
  belongs_to :author, polymorphic: true
  has_many_attached :attachments

  validates :body, presence: true
  validate :customer_can_comment_after_agent, on: :create
  validate :acceptable_attachments

  scope :ordered, -> { order(created_at: :asc) }

  private

  def customer_can_comment_after_agent
    return unless author_type == "Customer"
    return if ticket.comments.exists?(author_type: "Agent")

    errors.add(:base, "Cannot comment until an agent has responded")
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
