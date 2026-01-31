# frozen_string_literal: true

module Mutations
  class CreateDirectUpload < BaseMutation
    description "Create a presigned URL for direct file upload"

    argument :byte_size, Integer, required: true, description: "The size of the file in bytes"
    argument :checksum, String, required: true, description: "Base64 MD5 checksum of the file"
    argument :content_type, String, required: true, description: "The MIME type of the file"
    argument :filename, String, required: true, description: "The name of the file"

    field :direct_upload, Types::DirectUploadType, null: true

    ALLOWED_CONTENT_TYPES = [
      "image/jpeg",
      "image/png",
      "image/gif",
      "image/webp",
      "application/pdf",
    ].freeze

    MAX_FILE_SIZE = 10.megabytes

    def execute(filename:, content_type:, byte_size:, checksum:)
      unless ALLOWED_CONTENT_TYPES.include?(content_type)
        error!("File type not allowed. Allowed types: JPEG, PNG, GIF, WebP, PDF",
               field: "content_type", code: "INVALID_CONTENT_TYPE",)
      end

      if byte_size > MAX_FILE_SIZE
        error!("File size must be less than 10MB", field: "byte_size", code: "FILE_TOO_LARGE")
      end

      blob = ActiveStorage::Blob.create_before_direct_upload!(
        filename: filename,
        content_type: content_type,
        byte_size: byte_size,
        checksum: checksum,
        service_name: Rails.configuration.active_storage.service,
      )

      {
        direct_upload: {
          url: blob.service_url_for_direct_upload,
          headers: blob.service_headers_for_direct_upload.to_json,
          signed_id: blob.signed_id,
        },
      }
    end
  end
end
