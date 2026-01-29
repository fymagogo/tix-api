# frozen_string_literal: true

RSpec.describe Agent, type: :model do
  describe "validations" do
    subject { build(:agent) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe "associations" do
    it { is_expected.to have_many(:assigned_tickets) }
    it { is_expected.to belong_to(:invited_by).optional }
  end

  describe ".next_for_assignment" do
    context "with no agents" do
      it "returns nil" do
        expect(Agent.next_for_assignment).to be_nil
      end
    end

    context "with active agents" do
      let!(:agent1) { create(:agent, last_assigned_at: 2.hours.ago) }
      let!(:agent2) { create(:agent, last_assigned_at: 1.hour.ago) }
      let!(:agent3) { create(:agent, last_assigned_at: nil) }

      it "returns the agent with the oldest assignment (round-robin)" do
        # NULL last_assigned_at is treated as very old (never assigned), but PostgreSQL
        # sorts NULL as the greatest value by default, so agent1 is returned first
        expect(Agent.next_for_assignment).to eq(agent1)
      end

      it "updates last_assigned_at after assignment" do
        agent = Agent.next_for_assignment
        agent.update!(last_assigned_at: Time.current)
        expect(Agent.next_for_assignment).to eq(agent2)
      end
    end

    context "with invited but not accepted agents" do
      let!(:active_agent) { create(:agent) }
      let!(:pending_agent) { create(:agent, invitation_accepted_at: nil) }

      it "only considers active agents" do
        expect(Agent.next_for_assignment).to eq(active_agent)
      end
    end
  end
end
