# frozen_string_literal: true

RSpec.describe CommentPolicy do
  let(:customer) { create(:customer) }
  let(:agent) { create(:agent) }
  let(:ticket) { create(:ticket, customer: customer, assigned_agent: agent) }

  describe "#create?" do
    context "agent" do
      it "allows agent to create comment as first comment" do
        comment = build(:comment, ticket: ticket, author: agent)
        policy = described_class.new(agent, comment)
        expect(policy.create?).to be true
      end
    end

    context "customer" do
      context "when no agent has commented yet" do
        it "denies customer from creating first comment" do
          comment = build(:comment, ticket: ticket, author: customer)
          policy = described_class.new(customer, comment)
          expect(policy.create?).to be false
        end
      end

      context "when agent has already commented" do
        before { create(:comment, ticket: ticket, author: agent) }

        it "allows customer to create comment" do
          comment = build(:comment, ticket: ticket, author: customer)
          policy = described_class.new(customer, comment)
          expect(policy.create?).to be true
        end
      end
    end
  end

  describe "Scope" do
    let!(:comment1) { create(:comment, ticket: ticket, author: agent) }
    let!(:comment2) { create(:comment, ticket: ticket, author: customer) }

    it "returns all comments" do
      scope = described_class::Scope.new(agent, Comment).resolve
      expect(scope).to include(comment1, comment2)
    end
  end
end
