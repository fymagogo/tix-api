# frozen_string_literal: true

RSpec.describe GraphQLController, type: :request do
  describe "POST /graphql" do
    let(:customer) { create(:customer) }
    let(:query) do
      <<~GQL
        query Me {
          me {
            ... on Customer { id email }
          }
        }
      GQL
    end

    it "executes valid GraphQL query" do
      post "/graphql", params: { query: query }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to have_key("data")
    end

    it "handles string variables" do
      post "/graphql", params: { query: query, variables: "{}" }
      expect(response).to have_http_status(:ok)
    end

    it "handles hash variables" do
      post "/graphql", params: { query: query, variables: {} }
      expect(response).to have_http_status(:ok)
    end

    it "handles nil variables" do
      post "/graphql", params: { query: query, variables: nil }
      expect(response).to have_http_status(:ok)
    end

    it "handles empty string variables" do
      post "/graphql", params: { query: query, variables: "" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "#prepare_variables" do
    # Test the private method directly
    let(:controller) { described_class.new }

    it "handles ActionController::Parameters" do
      params = ActionController::Parameters.new({ foo: "bar" })
      result = controller.send(:prepare_variables, params)
      expect(result).to eq({ "foo" => "bar" })
    end

    it "raises for unexpected parameter types" do
      expect {
        controller.send(:prepare_variables, 12345)
      }.to raise_error(ArgumentError, /Unexpected parameter/)
    end
  end
end
