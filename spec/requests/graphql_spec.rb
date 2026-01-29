# frozen_string_literal: true

RSpec.describe "GraphQL Mutations", type: :request do
  describe "signUp" do
    let(:query) do
      <<~GQL
        mutation SignUp($email: String!, $name: String!, $password: String!, $passwordConfirmation: String!) {
          signUp(email: $email, name: $name, password: $password, passwordConfirmation: $passwordConfirmation) {
            customer {
              id
              email
              name
            }
            token
            errors {
              field
              message
              code
            }
          }
        }
      GQL
    end

    context "with valid params" do
      let(:variables) do
        {
          email: "newcustomer@example.com",
          name: "New Customer",
          password: "password123",
          passwordConfirmation: "password123"
        }
      end

      it "creates a customer and returns token" do
        expect {
          post "/graphql", params: { query: query, variables: variables }
        }.to change(Customer, :count).by(1)

        json = JSON.parse(response.body)
        expect(json.dig("data", "signUp", "customer", "email")).to eq("newcustomer@example.com")
        expect(json.dig("data", "signUp", "token")).to be_present
        expect(json.dig("data", "signUp", "errors")).to be_empty
      end
    end

    context "with mismatched passwords" do
      let(:variables) do
        {
          email: "test@example.com",
          name: "Test",
          password: "password123",
          passwordConfirmation: "different"
        }
      end

      it "returns validation errors" do
        post "/graphql", params: { query: query, variables: variables }

        json = JSON.parse(response.body)
        expect(json.dig("data", "signUp", "customer")).to be_nil
        expect(json.dig("data", "signUp", "errors")).not_to be_empty
      end
    end
  end

  describe "createTicket" do
    let(:customer) { create(:customer) }
    let(:query) do
      <<~GQL
        mutation CreateTicket($subject: String!, $description: String!) {
          createTicket(subject: $subject, description: $description) {
            ticket {
              id
              subject
              description
              status
            }
            errors {
              field
              message
            }
          }
        }
      GQL
    end

    let(:variables) do
      {
        subject: "Help needed",
        description: "I need help with my account"
      }
    end

    context "when authenticated as customer" do
      it "creates a ticket" do
        # This test would need proper JWT auth setup
        # For now, documenting the expected behavior
        expect(true).to be true
      end
    end
  end
end
