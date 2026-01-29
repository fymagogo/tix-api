# frozen_string_literal: true

class ExportMailer < ApplicationMailer
  def closed_tickets(agent, csv_data)
    @agent = agent
    attachments["closed_tickets_#{Date.current.iso8601}.csv"] = {
      mime_type: "text/csv",
      content: csv_data,
    }

    mail(
      to: agent.email,
      subject: "Your closed tickets export is ready",
    )
  end
end
