# frozen_string_literal: true

module Types
  class DirectUploadType < Types::BaseObject
    description "Presigned URL for direct file upload"

    field :headers, String, null: false, description: "JSON headers to include in the upload request"
    field :signed_id, String, null: false, description: "The signed blob ID for attaching to records"
    field :url, String, null: false, description: "The URL to upload the file to"
  end
end
