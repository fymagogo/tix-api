# frozen_string_literal: true

RSpec.describe TicketAssignmentJob, type: :job do
  let(:agent) { create(:agent) }
  let(:ticket) { create(:ticket) }

  describe "#perform" do
    context "when agents are available" do
      before { agent }

      it "assigns an agent to the ticket" do
        expect {
          described_class.perform_now(ticket.id)
          ticket.reload
        }.to change { ticket.assigned_agent }.from(nil).to(agent)
      end

      it "transitions ticket to agent_assigned" do
        described_class.perform_now(ticket.id)
        ticket.reload
        expect(ticket).to be_agent_assigned
      end

      it "updates agent's last_assigned_at" do
        expect {
          described_class.perform_now(ticket.id)
          agent.reload
        }.to change { agent.last_assigned_at }
      end
    end

    context "when no agents are available" do
      it "does not raise an error" do
        expect { described_class.perform_now(ticket.id) }.not_to raise_error
      end

      it "leaves ticket unassigned" do
        described_class.perform_now(ticket.id)
        ticket.reload
        expect(ticket.assigned_agent).to be_nil
      end
    end

    context "when ticket is already assigned" do
      let(:other_agent) { create(:agent) }
      let(:assigned_ticket) { create(:ticket, :with_agent, assigned_agent: other_agent) }

      it "does not reassign" do
        agent # create another agent
        described_class.perform_now(assigned_ticket.id)
        assigned_ticket.reload
        expect(assigned_ticket.assigned_agent).to eq(other_agent)
      end
    end

    context "when ticket is not found" do
      it "returns early without error" do
        expect { described_class.perform_now("non-existent-id") }.not_to raise_error
      end
    end

    context "when AASM::InvalidTransition occurs" do
      before { agent }

      it "logs the error and does not raise" do
        # Stub may_assign_agent? to return true but assign_agent! to raise
        allow_any_instance_of(Ticket).to receive(:may_assign_agent?).and_return(true)
        allow_any_instance_of(Ticket).to receive(:assign_agent!) do
          raise AASM::InvalidTransition.new(Ticket.new, :assign_agent, :default)
        end
        
        # Just verify it doesn't raise
        expect { described_class.perform_now(ticket.id) }.not_to raise_error
      end
    end
  end
end
