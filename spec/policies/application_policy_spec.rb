# frozen_string_literal: true

RSpec.describe ApplicationPolicy do
  let(:customer) { create(:customer) }
  let(:agent) { create(:agent) }
  let(:record) { double("record") }

  describe "default policy methods" do
    let(:policy) { described_class.new(customer, record) }

    it "denies index? by default" do
      expect(policy.index?).to be false
    end

    it "denies show? by default" do
      expect(policy.show?).to be false
    end

    it "denies create? by default" do
      expect(policy.create?).to be false
    end

    it "denies update? by default" do
      expect(policy.update?).to be false
    end

    it "denies destroy? by default" do
      expect(policy.destroy?).to be false
    end

    it "delegates new? to create?" do
      expect(policy.new?).to eq(policy.create?)
    end

    it "delegates edit? to update?" do
      expect(policy.edit?).to eq(policy.update?)
    end
  end

  describe "#agent?" do
    it "returns true for agent users" do
      policy = described_class.new(agent, record)
      expect(policy.send(:agent?)).to be true
    end

    it "returns false for customer users" do
      policy = described_class.new(customer, record)
      expect(policy.send(:agent?)).to be false
    end
  end

  describe "#customer?" do
    it "returns true for customer users" do
      policy = described_class.new(customer, record)
      expect(policy.send(:customer?)).to be true
    end

    it "returns false for agent users" do
      policy = described_class.new(agent, record)
      expect(policy.send(:customer?)).to be false
    end
  end

  describe "Scope" do
    it "raises NotImplementedError for unimplemented resolve" do
      scope = described_class::Scope.new(customer, Ticket)
      expect { scope.resolve }.to raise_error(NotImplementedError)
    end
  end
end
