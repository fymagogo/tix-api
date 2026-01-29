# frozen_string_literal: true

RSpec.describe TicketPolicy do
  let(:customer) { create(:customer) }
  let(:other_customer) { create(:customer) }
  let(:agent) { create(:agent) }
  let(:admin) { create(:agent, :admin) }
  let(:ticket) { create(:ticket, customer: customer) }

  describe "#index?" do
    it "allows customer to list tickets" do
      policy = described_class.new(customer, Ticket)
      expect(policy.index?).to be true
    end

    it "allows agent to list tickets" do
      policy = described_class.new(agent, Ticket)
      expect(policy.index?).to be true
    end
  end

  describe "#show?" do
    it "allows customer to view their own ticket" do
      policy = described_class.new(customer, ticket)
      expect(policy.show?).to be true
    end

    it "denies customer from viewing other customers ticket" do
      policy = described_class.new(other_customer, ticket)
      expect(policy.show?).to be false
    end

    it "allows agent to view any ticket" do
      policy = described_class.new(agent, ticket)
      expect(policy.show?).to be true
    end
  end

  describe "#create?" do
    it "allows customer to create ticket" do
      policy = described_class.new(customer, Ticket)
      expect(policy.create?).to be true
    end

    it "denies agent from creating ticket" do
      policy = described_class.new(agent, Ticket)
      expect(policy.create?).to be false
    end
  end

  describe "#update?" do
    it "denies customer from updating ticket" do
      policy = described_class.new(customer, ticket)
      expect(policy.update?).to be false
    end

    it "allows agent to update ticket" do
      policy = described_class.new(agent, ticket)
      expect(policy.update?).to be true
    end
  end

  describe "#transition?" do
    let(:assigned_ticket) { create(:ticket, customer: customer, assigned_agent: agent, status: :agent_assigned) }

    it "denies customer from transitioning ticket" do
      policy = described_class.new(customer, assigned_ticket)
      expect(policy.transition?).to be false
    end

    it "allows assigned agent to transition ticket" do
      policy = described_class.new(agent, assigned_ticket)
      expect(policy.transition?).to be true
    end

    it "denies unassigned agent from transitioning ticket" do
      other_agent = create(:agent)
      policy = described_class.new(other_agent, assigned_ticket)
      expect(policy.transition?).to be false
    end

    it "allows admin to transition any ticket" do
      policy = described_class.new(admin, assigned_ticket)
      expect(policy.transition?).to be true
    end
  end

  describe "#assign?" do
    it "allows agent to assign ticket" do
      policy = described_class.new(agent, ticket)
      expect(policy.assign?).to be true
    end

    it "denies customer from assigning ticket" do
      policy = described_class.new(customer, ticket)
      expect(policy.assign?).to be false
    end
  end

  describe "Scope" do
    let!(:customer_ticket) { create(:ticket, customer: customer) }
    let!(:other_ticket) { create(:ticket, customer: other_customer) }

    it "returns only customer's own tickets" do
      scope = described_class::Scope.new(customer, Ticket).resolve
      expect(scope).to include(customer_ticket)
      expect(scope).not_to include(other_ticket)
    end

    it "returns all tickets for agents" do
      scope = described_class::Scope.new(agent, Ticket).resolve
      expect(scope).to include(customer_ticket, other_ticket)
    end

    it "returns no tickets for nil user" do
      scope = described_class::Scope.new(nil, Ticket).resolve
      expect(scope).to be_empty
    end
  end
end
