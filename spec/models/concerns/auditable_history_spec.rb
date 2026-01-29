# frozen_string_literal: true

RSpec.describe AuditableHistory, type: :model do
  describe "included in Ticket" do
    let(:agent) { create(:agent, name: "Test Agent") }
    let(:customer) { create(:customer) }
    let(:ticket) { create(:ticket, customer: customer) }

    describe "#human_readable_history" do
      it "includes created event" do
        history = ticket.human_readable_history
        events = history.map(&:event)
        expect(events).to include("Ticket created")
      end

      it "includes status change events" do
        ticket.update!(assigned_agent: agent)
        ticket.assign_agent!
        ticket.start_progress!

        history = ticket.human_readable_history
        events = history.map(&:event)
        expect(events).to include("Status changed to In Progress")
      end

      it "includes agent assignment event" do
        ticket.update!(assigned_agent: agent)
        ticket.assign_agent!

        history = ticket.human_readable_history
        events = history.map(&:event)
        expect(events.any? { |e| e.include?("Assigned to") }).to be true
      end

      it "includes reassignment event" do
        new_agent = create(:agent, name: "New Agent")
        ticket.update!(assigned_agent: agent)
        ticket.assign_agent!
        ticket.update!(assigned_agent: new_agent)

        history = ticket.human_readable_history
        events = history.map(&:event)
        expect(events.any? { |e| e.include?("Reassigned") }).to be true
      end

      it "does not show status change to agent_assigned" do
        ticket.update!(assigned_agent: agent)
        ticket.assign_agent!

        history = ticket.human_readable_history
        events = history.map(&:event)
        expect(events).not_to include("Status changed to Agent Assigned")
      end
    end

    describe "#audit_history" do
      it "returns audit entries" do
        history = ticket.audit_history
        expect(history).to be_an(Array)
        expect(history.first).to respond_to(:action)
        expect(history.first).to respond_to(:changes)
      end

      it "filters sensitive fields" do
        history = ticket.audit_history
        history.each do |entry|
          entry.changes.each do |change|
            expect(AuditableHistory::SENSITIVE_FIELDS).not_to include(change[:field])
          end
        end
      end
    end

    describe "#audit_history_for" do
      it "returns changes for specific field" do
        ticket.update!(subject: "Updated subject")
        history = ticket.audit_history_for(:subject)
        expect(history.length).to be >= 1
      end

      it "excludes sensitive fields" do
        history = ticket.audit_history_for(:encrypted_password)
        expect(history).to be_empty
      end
    end

    describe "#status_changes" do
      it "returns status transitions" do
        ticket.update!(assigned_agent: agent)
        ticket.assign_agent!
        ticket.start_progress!

        changes = ticket.status_changes
        expect(changes).to be_an(Array)
        expect(changes.map { |c| c[:to] }).to include("agent_assigned", "in_progress")
      end
    end
  end

  describe "included in Agent" do
    let(:admin) { create(:agent, :admin) }
    let!(:invited_agent) { Agent.invite!({ email: "new@tix.test", name: "New Agent" }, admin) }

    describe "#human_readable_history" do
      it "includes invited event" do
        history = invited_agent.human_readable_history
        events = history.map(&:event)
        expect(events.any? { |e| e.include?("Invited") }).to be true
      end

      it "includes invitation accepted event" do
        # Use the class method which accepts attributes
        Agent.accept_invitation!(
          invitation_token: invited_agent.raw_invitation_token,
          password: "password123",
          password_confirmation: "password123"
        )
        
        history = invited_agent.reload.human_readable_history
        events = history.map(&:event)
        expect(events).to include("Invitation accepted")
      end

      it "includes password reset requested event" do
        regular_agent = create(:agent)
        regular_agent.send_reset_password_instructions
        history = regular_agent.human_readable_history
        events = history.map(&:event)
        expect(events).to include("Password reset requested")
      end

      it "shows Account created for non-invited agent" do
        regular_agent = create(:agent)
        history = regular_agent.human_readable_history
        events = history.map(&:event)
        expect(events).to include("Account created")
      end
    end
  end

  describe "agent unassignment" do
    let(:agent) { create(:agent) }
    let(:customer) { create(:customer) }
    let(:ticket) { create(:ticket, customer: customer, assigned_agent: agent, status: :agent_assigned) }

    it "includes agent unassigned event" do
      ticket.update!(assigned_agent: nil)

      history = ticket.human_readable_history
      events = history.map(&:event)
      expect(events).to include("Agent unassigned")
    end
  end

  describe "included in Customer" do
    let(:customer) { create(:customer) }

    describe "#human_readable_history" do
      it "includes account created event" do
        history = customer.human_readable_history
        events = history.map(&:event)
        expect(events).to include("Account created")
      end
    end
  end
end
