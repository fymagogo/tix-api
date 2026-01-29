# frozen_string_literal: true

RSpec.describe AgentPolicy do
  let(:agent) { create(:agent) }
  let(:admin) { create(:agent, :admin) }
  let(:customer) { create(:customer) }
  let(:target_agent) { create(:agent) }

  describe "#index?" do
    it "allows agents to list agents" do
      policy = described_class.new(agent, Agent)
      expect(policy.index?).to be true
    end

    it "denies customers from listing agents" do
      policy = described_class.new(customer, Agent)
      expect(policy.index?).to be false
    end
  end

  describe "#show?" do
    it "allows agents to view agents" do
      policy = described_class.new(agent, target_agent)
      expect(policy.show?).to be true
    end

    it "denies customers from viewing agents" do
      policy = described_class.new(customer, target_agent)
      expect(policy.show?).to be false
    end
  end

  describe "#invite?" do
    it "allows agents to invite" do
      policy = described_class.new(agent, Agent)
      expect(policy.invite?).to be true
    end

    it "denies customers from inviting" do
      policy = described_class.new(customer, Agent)
      expect(policy.invite?).to be false
    end
  end

  describe "Scope" do
    let!(:agent1) { create(:agent) }
    let!(:agent2) { create(:agent) }

    context "as agent" do
      it "returns all agents" do
        scope = described_class::Scope.new(agent, Agent).resolve
        expect(scope).to include(agent1, agent2)
      end
    end

    context "as customer" do
      it "returns no agents" do
        scope = described_class::Scope.new(customer, Agent).resolve
        expect(scope).to be_empty
      end
    end
  end
end
