# frozen_string_literal: true

RSpec.describe Ticket do
  describe "validations" do
    subject { build(:ticket) }

    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:description) }
  end

  describe "ticket_number" do
    it "is generated on create" do
      ticket = create(:ticket)
      expect(ticket.ticket_number).to be_present
      expect(ticket.ticket_number).to match(/\A[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{8}\z/)
    end

    it "is unique" do
      t1 = create(:ticket)
      t2 = create(:ticket)
      expect(t1.ticket_number).not_to eq(t2.ticket_number)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:assigned_agent).optional }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
  end

  describe "state machine" do
    let(:agent) { create(:agent) }
    let(:ticket) { create(:ticket) }

    it "starts in new state" do
      expect(ticket).to be_new
    end

    context "transitions" do
      before { ticket.update!(assigned_agent: agent) }

      it "can transition from new to agent_assigned" do
        expect(ticket.may_assign_agent?).to be true
        ticket.assign_agent!
        expect(ticket).to be_agent_assigned
      end

      it "can transition from agent_assigned to in_progress" do
        ticket.assign_agent!
        expect(ticket.may_start_progress?).to be true
        ticket.start_progress!
        expect(ticket).to be_in_progress
      end

      it "can transition from in_progress to hold" do
        ticket.assign_agent!
        ticket.start_progress!
        expect(ticket.may_put_on_hold?).to be true
        ticket.put_on_hold!
        expect(ticket).to be_hold
      end

      it "can transition from hold back to in_progress" do
        ticket.assign_agent!
        ticket.start_progress!
        ticket.put_on_hold!
        expect(ticket.may_resume?).to be true
        ticket.resume!
        expect(ticket).to be_in_progress
      end

      it "can transition from in_progress to closed" do
        ticket.assign_agent!
        ticket.start_progress!
        expect(ticket.may_close?).to be true
        ticket.close!
        expect(ticket).to be_closed
        expect(ticket.closed_at).to be_present
      end
    end
  end

  describe "#status_changes" do
    let(:agent) { create(:agent) }
    let(:ticket) { create(:ticket, assigned_agent: agent) }

    it "returns status changes from audit log" do
      ticket.assign_agent!
      ticket.start_progress!

      changes = ticket.status_changes
      expect(changes.length).to be >= 2
      # After create (new), assign_agent! transitions to agent_assigned,
      # then start_progress! transitions to in_progress
      expect(changes.pluck(:to)).to include("agent_assigned", "in_progress")
    end
  end

  describe "ticket_number collision retry" do
    let(:customer) { create(:customer) }

    it "generates unique ticket numbers" do
      tickets = 5.times.map { create(:ticket, customer: customer) }
      numbers = tickets.map(&:ticket_number)
      expect(numbers.uniq.length).to eq(5)
    end
  end
end
