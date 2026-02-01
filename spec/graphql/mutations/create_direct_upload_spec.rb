# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::CreateDirectUpload, type: :graphql do
  let(:customer) { create(:customer) }
  let(:agent) { create(:agent) }

  let(:mutation) do
    <<~GQL
      mutation CreateDirectUpload($filename: String!, $contentType: String!, $byteSize: Int!, $checksum: String!) {
        createDirectUpload(filename: $filename, contentType: $contentType, byteSize: $byteSize, checksum: $checksum) {
          directUpload {
            signedId
            url
            headers
          }
          errors {
            field
            message
            code
          }
        }
      }
    GQL
  end

  let(:valid_variables) do
    {
      filename: "test-image.png",
      contentType: "image/png",
      byteSize: 1024,
      checksum: Base64.strict_encode64(SecureRandom.random_bytes(16)),
    }
  end

  context "when user is authenticated as customer" do
    it "creates a direct upload successfully" do
      result = execute_graphql(
        query: mutation,
        variables: valid_variables,
        context: { current_user: customer },
      )

      data = result.dig("data", "createDirectUpload")
      expect(data["errors"]).to be_empty
      expect(data["directUpload"]).to be_present
      expect(data["directUpload"]["signedId"]).to be_present
      expect(data["directUpload"]["url"]).to be_present
    end
  end

  context "when user is authenticated as agent" do
    it "creates a direct upload successfully" do
      result = execute_graphql(
        query: mutation,
        variables: valid_variables,
        context: { current_user: agent },
      )

      data = result.dig("data", "createDirectUpload")
      expect(data["errors"]).to be_empty
      expect(data["directUpload"]).to be_present
    end
  end

  context "when user is not authenticated" do
    it "returns an error" do
      result = execute_graphql(
        query: mutation,
        variables: valid_variables,
        context: {},
      )

      expect(result["errors"].first["message"]).to eq("Authentication required")
      expect(result["errors"].first["extensions"]["code"]).to eq("UNAUTHENTICATED")
    end
  end

  context "with invalid content type" do
    it "returns an error" do
      result = execute_graphql(
        query: mutation,
        variables: valid_variables.merge(contentType: "application/zip"),
        context: { current_user: customer },
      )

      data = result.dig("data", "createDirectUpload")
      expect(data["errors"]).not_to be_empty
      expect(data["errors"].first["message"]).to include("not allowed")
    end
  end

  context "with file size exceeding limit" do
    it "returns an error" do
      result = execute_graphql(
        query: mutation,
        variables: valid_variables.merge(byteSize: 20 * 1024 * 1024),
        context: { current_user: customer },
      )

      data = result.dig("data", "createDirectUpload")
      expect(data["errors"]).not_to be_empty
      expect(data["errors"].first["message"]).to include("10")
    end
  end
end
