# frozen_string_literal: true

class ExportMailer < ApplicationMailer
  def closed_tickets(agent, csv_data, filename: nil)
    @agent = agent
    export_filename = filename || "closed_tickets_#{Date.current.iso8601}.csv"

    attachments[export_filename] = {
      mime_type: "text/csv",
      content: csv_data,
    }

    mail(
      to: agent.email,
      subject: "Your closed tickets export is ready",
    )
  end
end
