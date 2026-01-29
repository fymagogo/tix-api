# frozen_string_literal: true

RSpec.describe Comment do
  describe "validations" do
    subject { build(:comment) }

    it { is_expected.to validate_presence_of(:body) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:ticket) }
    it { is_expected.to belong_to(:author) }
  end

  describe "customer comment validation" do
    let(:customer) { create(:customer) }
    let(:agent) { create(:agent) }
    let(:ticket) { create(:ticket, customer: customer, assigned_agent: agent) }

    context "when customer is the first to comment" do
      it "is invalid" do
        comment = build(:comment, ticket: ticket, author: customer)
        expect(comment).not_to be_valid
        expect(comment.errors[:base]).to include("Cannot comment until an agent has responded")
      end
    end

    context "when agent has already commented" do
      before { create(:comment, ticket: ticket, author: agent) }

      it "allows customer to comment" do
        comment = build(:comment, ticket: ticket, author: customer)
        expect(comment).to be_valid
      end
    end

    context "when author is an agent" do
      it "is valid even as first comment" do
        comment = build(:comment, ticket: ticket, author: agent)
        expect(comment).to be_valid
      end
    end
  end

  describe ".ordered" do
    let(:ticket) { create(:ticket) }
    let(:agent) { create(:agent) }

    it "returns comments in chronological order" do
      comment1 = create(:comment, ticket: ticket, author: agent, created_at: 2.hours.ago)
      comment2 = create(:comment, ticket: ticket, author: agent, created_at: 1.hour.ago)
      comment3 = create(:comment, ticket: ticket, author: agent, created_at: Time.current)

      expect(ticket.comments.ordered).to eq([comment1, comment2, comment3])
    end
  end
end
