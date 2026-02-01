# frozen_string_literal: true

RSpec.describe Types::QueryType, type: :graphql do
  describe "me" do
    let(:query) do
      <<~GQL
        query Me {
          me {
            ... on Customer { id email name }
            ... on Agent { id email name isAdmin }
          }
        }
      GQL
    end

    context "as customer" do
      let(:customer) { create(:customer) }

      it "returns current customer" do
        result = execute_graphql(query: query, context: { current_user: customer })

        data = result["data"]["me"]
        expect(data["email"]).to eq(customer.email)
        expect(data["name"]).to eq(customer.name)
      end
    end

    context "as agent" do
      let(:agent) { create(:agent, :admin) }

      it "returns current agent" do
        result = execute_graphql(query: query, context: { current_user: agent })

        data = result["data"]["me"]
        expect(data["email"]).to eq(agent.email)
        expect(data["isAdmin"]).to be true
      end
    end

    context "not authenticated" do
      it "returns null" do
        result = execute_graphql(query: query, context: { current_user: nil })

        expect(result["data"]["me"]).to be_nil
      end
    end
  end

  describe "ticket" do
    let(:query) do
      <<~GQL
        query Ticket($id: ID!) {
          ticket(id: $id) {
            id
            subject
            status
          }
        }
      GQL
    end

    let(:customer) { create(:customer) }
    let(:other_customer) { create(:customer) }
    let(:agent) { create(:agent) }
    let(:ticket) { create(:ticket, customer: customer) }

    context "as owner customer" do
      it "returns the ticket" do
        result = execute_graphql(query: query, variables: { id: ticket.id }, context: { current_user: customer })

        expect(result["data"]["ticket"]["id"]).to eq(ticket.id)
      end
    end

    context "as other customer" do
      it "raises not authorized error" do
        result = execute_graphql(query: query, variables: { id: ticket.id }, context: { current_user: other_customer })

        expect(result["errors"]).to be_present
      end
    end

    context "as agent" do
      it "returns the ticket" do
        result = execute_graphql(query: query, variables: { id: ticket.id }, context: { current_user: agent })

        expect(result["data"]["ticket"]["id"]).to eq(ticket.id)
      end
    end
  end

  describe "agents" do
    let(:query) do
      <<~GQL
        query Agents {
          agents {
            id
            name
            email
          }
        }
      GQL
    end

    let!(:agent) { create(:agent) }
    let!(:pending_agent) { create(:agent, invitation_accepted_at: nil, invitation_token: "some_token") }
    let(:customer) { create(:customer) }

    context "as agent" do
      it "returns active agents" do
        result = execute_graphql(query: query, context: { current_user: agent })

        agents = result["data"]["agents"]
        expect(agents.any? { |a| a["id"] == agent.id }).to be true
      end

      it "includes pending agents" do
        result = execute_graphql(query: query, context: { current_user: agent })

        agents = result["data"]["agents"]
        expect(agents.any? { |a| a["id"] == pending_agent.id }).to be true
      end
    end

    context "as customer" do
      it "raises not authorized error" do
        result = execute_graphql(query: query, context: { current_user: customer })

        expect(result["errors"]).to be_present
      end
    end
  end

  describe "agent" do
    let(:query) do
      <<~GQL
        query Agent($id: ID!) {
          agent(id: $id) {
            id
            name
            email
          }
        }
      GQL
    end

    let(:agent) { create(:agent) }
    let(:other_agent) { create(:agent) }
    let(:customer) { create(:customer) }

    context "as agent" do
      it "returns the agent" do
        result = execute_graphql(query: query, variables: { id: other_agent.id }, context: { current_user: agent })

        expect(result["data"]["agent"]["id"]).to eq(other_agent.id)
      end
    end

    context "as customer" do
      it "raises not authorized error" do
        result = execute_graphql(query: query, variables: { id: agent.id }, context: { current_user: customer })

        expect(result["errors"]).to be_present
      end
    end
  end
end
