# frozen_string_literal: true

RSpec.describe TixApiSchema, type: :graphql do
  describe "error handlers" do
    describe "RecordNotFound" do
      let(:agent) { create(:agent) }
      let(:query) do
        <<~GQL
          query GetTicket($id: ID!) {
            ticket(id: $id) {
              id subject
            }
          }
        GQL
      end

      it "rescues RecordNotFound and returns GraphQL error" do
        result = execute_graphql(
          query: query,
          variables: { id: "non-existent-uuid" },
          context: { current_user: agent }
        )

        expect(result["errors"]).to be_present
        expect(result["errors"].first["message"]).to eq("Record not found")
        expect(result["errors"].first["extensions"]["code"]).to eq("NOT_FOUND")
      end
    end

    describe "Pundit::NotAuthorizedError" do
      let(:customer) { create(:customer) }
      let(:other_customer) { create(:customer) }
      let(:ticket) { create(:ticket, customer: other_customer) }
      let(:query) do
        <<~GQL
          query GetTicket($id: ID!) {
            ticket(id: $id) {
              id subject
            }
          }
        GQL
      end

      it "rescues NotAuthorizedError and returns GraphQL error" do
        result = execute_graphql(
          query: query,
          variables: { id: ticket.id },
          context: { current_user: customer }
        )

        expect(result["errors"]).to be_present
        expect(result["errors"].first["message"]).to eq("Not authorized")
        expect(result["errors"].first["extensions"]["code"]).to eq("UNAUTHORIZED")
      end
    end
  end

  describe ".resolve_type" do
    it "resolves Customer type" do
      customer = build(:customer)
      result = described_class.resolve_type(nil, customer, nil)
      # GraphQL-Ruby may wrap result, check type is included
      type = result.is_a?(Array) ? result.first : result
      expect(type).to eq(Types::CustomerType)
    end

    it "resolves Agent type" do
      agent = build(:agent)
      result = described_class.resolve_type(nil, agent, nil)
      type = result.is_a?(Array) ? result.first : result
      expect(type).to eq(Types::AgentType)
    end

    it "resolves Ticket type" do
      ticket = build(:ticket)
      result = described_class.resolve_type(nil, ticket, nil)
      type = result.is_a?(Array) ? result.first : result
      expect(type).to eq(Types::TicketType)
    end

    it "resolves Comment type" do
      comment = build(:comment)
      result = described_class.resolve_type(nil, comment, nil)
      type = result.is_a?(Array) ? result.first : result
      expect(type).to eq(Types::CommentType)
    end

    it "raises for unknown type" do
      unknown = Object.new
      expect {
        described_class.resolve_type(nil, unknown, nil)
      }.to raise_error(GraphQL::RequiredImplementationMissingError, /Unknown type/)
    end
  end
end
