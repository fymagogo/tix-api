# frozen_string_literal: true

RSpec.describe TicketExportJob, type: :job do
  include ActiveJob::TestHelper

  let(:agent) { create(:agent) }

  describe "#perform" do
    let!(:closed_ticket) do
      create(:ticket, :closed,
             updated_at: 2.weeks.ago,
             subject: "Closed ticket")
    end

    it "generates CSV for closed tickets" do
      expect(TicketExporter).to receive(:generate).and_call_original
      perform_enqueued_jobs { described_class.perform_later(agent.id) }
    end

    it "sends email with export" do
      expect { perform_enqueued_jobs { described_class.perform_later(agent.id) } }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "is enqueued in exports queue" do
      expect { described_class.perform_later(agent.id) }
        .to have_enqueued_job.on_queue("exports")
    end
  end
end
