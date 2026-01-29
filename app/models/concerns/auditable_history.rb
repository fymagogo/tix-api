# frozen_string_literal: true

# Provides a consistent interface for accessing audit history
# across all audited models (Ticket, Agent, Customer, etc.)
#
# Usage:
#   class MyModel < ApplicationRecord
#     include AuditableHistory
#     audited
#   end
#
#   model.audit_history # => Array of audit entry hashes
#   model.human_readable_history # => Array of human-readable events
#
module AuditableHistory
  extend ActiveSupport::Concern

  # Fields that should never be exposed in audit history
  SENSITIVE_FIELDS = %w[
    encrypted_password
    reset_password_token
    invitation_token
    jti
    current_sign_in_ip
    last_sign_in_ip
  ].freeze

  # Human-readable status labels
  STATUS_LABELS = {
    "new" => "New",
    "agent_assigned" => "Agent Assigned",
    "in_progress" => "In Progress",
    "hold" => "On Hold",
    "closed" => "Closed"
  }.freeze

  included do
    # Ensure audited is available
    raise "AuditableHistory requires the model to include `audited`" unless respond_to?(:audited)
  end

  # Returns human-readable history events appropriate for the model type
  def human_readable_history
    events = []

    audits.order(created_at: :asc).each do |audit|
      events.concat(build_history_events(audit))
    end

    events.sort_by(&:occurred_at).reverse
  end

  # Returns a formatted array of all audit entries for this record
  # Each entry includes action, changes, timestamp, and who made the change
  def audit_history
    audits.order(created_at: :desc).map do |audit|
      AuditEntry.new(
        id: audit.id,
        action: audit.action,
        changes: format_changes(filter_sensitive_fields(audit.audited_changes)),
        changed_at: audit.created_at,
        changed_by: audit.user,
        version: audit.version
      )
    end
  end

  # Returns audit entries filtered by a specific field
  def audit_history_for(field)
    field_str = field.to_s
    return [] if SENSITIVE_FIELDS.include?(field_str)

    audits
      .where("audited_changes ? :field", field: field_str)
      .order(created_at: :desc)
      .map do |audit|
        changes = audit.audited_changes[field_str]
        AuditEntry.new(
          id: audit.id,
          action: audit.action,
          changes: [format_single_change(field_str, changes)],
          changed_at: audit.created_at,
          changed_by: audit.user,
          version: audit.version
        )
      end
  end

  private

  def build_history_events(audit)
    case self.class.name
    when "Ticket"
      build_ticket_history_events(audit)
    when "Agent"
      build_agent_history_events(audit)
    when "Customer"
      build_customer_history_events(audit)
    else
      build_generic_history_events(audit)
    end
  end

  def build_ticket_history_events(audit)
    events = []
    changes = audit.audited_changes

    if audit.action == "create"
      events << HistoryEvent.new(
        id: "#{audit.id}-create",
        event: "Ticket created",
        occurred_at: audit.created_at,
        actor: audit.user
      )
    end

    # Status changes (skip "agent_assigned" - we show assignment separately, skip initial status on create)
    if changes["status"] && audit.action != "create"
      old_status, new_status = extract_change(changes["status"])
      # Don't show status change to agent_assigned - we show "Assigned to X" instead
      if new_status && old_status != new_status && new_status != "agent_assigned"
        label = STATUS_LABELS[new_status] || new_status.titleize
        events << HistoryEvent.new(
          id: "#{audit.id}-status",
          event: "Status changed to #{label}",
          occurred_at: audit.created_at,
          actor: audit.user
        )
      end
    end

    # Agent assignment
    if changes["assigned_agent_id"]
      old_id, new_id = extract_change(changes["assigned_agent_id"])
      if new_id.present?
        agent = Agent.find_by(id: new_id)
        agent_name = agent&.name || "Unknown Agent"

        if old_id.present?
          # Reassignment
          actor_name = audit.user&.name
          event_text = actor_name ? "Reassigned to #{agent_name} by #{actor_name}" : "Reassigned to #{agent_name}"
          events << HistoryEvent.new(
            id: "#{audit.id}-agent",
            event: event_text,
            occurred_at: audit.created_at,
            actor: audit.user
          )
        else
          # Initial assignment
          events << HistoryEvent.new(
            id: "#{audit.id}-agent",
            event: "Assigned to #{agent_name}",
            occurred_at: audit.created_at,
            actor: audit.user
          )
        end
      elsif old_id.present? && new_id.nil?
        events << HistoryEvent.new(
          id: "#{audit.id}-unassign",
          event: "Agent unassigned",
          occurred_at: audit.created_at,
          actor: audit.user
        )
      end
    end

    events
  end

  def build_agent_history_events(audit)
    events = []
    changes = audit.audited_changes

    if audit.action == "create"
      invited_by_id = changes["invited_by_id"]
      invited_by_id = invited_by_id.is_a?(Array) ? invited_by_id[1] : invited_by_id

      if invited_by_id.present?
        inviter = Agent.find_by(id: invited_by_id)
        inviter_name = inviter&.name || "Unknown"
        events << HistoryEvent.new(
          id: "#{audit.id}-create",
          event: "Invited by #{inviter_name}",
          occurred_at: audit.created_at,
          actor: inviter
        )
      else
        events << HistoryEvent.new(
          id: "#{audit.id}-create",
          event: "Account created",
          occurred_at: audit.created_at,
          actor: audit.user
        )
      end
    end

    # Invitation accepted
    if changes["invitation_accepted_at"]
      old_val, new_val = extract_change(changes["invitation_accepted_at"])
      if new_val.present? && old_val.nil?
        events << HistoryEvent.new(
          id: "#{audit.id}-accepted",
          event: "Invitation accepted",
          occurred_at: audit.created_at,
          actor: nil
        )
      end
    end

    # Password reset
    if changes["reset_password_sent_at"]
      old_val, new_val = extract_change(changes["reset_password_sent_at"])
      if new_val.present?
        events << HistoryEvent.new(
          id: "#{audit.id}-reset",
          event: "Password reset requested",
          occurred_at: audit.created_at,
          actor: nil
        )
      end
    end

    events
  end

  def build_customer_history_events(audit)
    events = []

    if audit.action == "create"
      events << HistoryEvent.new(
        id: "#{audit.id}-create",
        event: "Account created",
        occurred_at: audit.created_at,
        actor: nil
      )
    end

    events
  end

  def build_generic_history_events(audit)
    event_text = case audit.action
                 when "create" then "Created"
                 when "update" then "Updated"
                 when "destroy" then "Deleted"
                 else audit.action.titleize
                 end

    [HistoryEvent.new(
      id: "#{audit.id}-#{audit.action}",
      event: event_text,
      occurred_at: audit.created_at,
      actor: audit.user
    )]
  end

  def extract_change(value)
    if value.is_a?(Array)
      [value[0], value[1]]
    else
      [nil, value]
    end
  end

  def filter_sensitive_fields(audited_changes)
    audited_changes.except(*SENSITIVE_FIELDS)
  end

  def format_changes(audited_changes)
    audited_changes.map do |field, value|
      format_single_change(field, value)
    end
  end

  def format_single_change(field, value)
    if value.is_a?(Array)
      { field: field, from: value[0]&.to_s, to: value[1]&.to_s }
    else
      { field: field, from: nil, to: value&.to_s }
    end
  end

  # Value object for audit entries
  class AuditEntry
    attr_reader :id, :action, :changes, :changed_at, :changed_by, :version

    def initialize(id:, action:, changes:, changed_at:, changed_by:, version:)
      @id = id
      @action = action
      @changes = changes
      @changed_at = changed_at
      @changed_by = changed_by
      @version = version
    end
  end

  # Value object for human-readable history events
  class HistoryEvent
    attr_reader :id, :event, :occurred_at, :actor

    def initialize(id:, event:, occurred_at:, actor:)
      @id = id
      @event = event
      @occurred_at = occurred_at
      @actor = actor
    end
  end
end
