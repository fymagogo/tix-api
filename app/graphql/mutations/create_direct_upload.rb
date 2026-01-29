# frozen_string_literal: true

module Mutations
  class CreateDirectUpload < BaseMutation
    description "Create a presigned URL for direct file upload"

    argument :byte_size, Integer, required: true, description: "The size of the file in bytes"
    argument :checksum, String, required: true, description: "Base64 MD5 checksum of the file"
    argument :content_type, String, required: true, description: "The MIME type of the file"
    argument :filename, String, required: true, description: "The name of the file"

    field :direct_upload, Types::DirectUploadType, null: true
    field :errors, [Types::ErrorType], null: false

    ALLOWED_CONTENT_TYPES = [
      "image/jpeg",
      "image/png",
      "image/gif",
      "image/webp",
      "application/pdf",
    ].freeze

    MAX_FILE_SIZE = 10.megabytes

    def resolve(filename:, content_type:, byte_size:, checksum:)
      unless context[:current_user]
        return {
          direct_upload: nil,
          errors: [{ message: "You must be logged in to upload files", code: "UNAUTHORIZED" }],
        }
      end

      unless ALLOWED_CONTENT_TYPES.include?(content_type)
        return {
          direct_upload: nil,
          errors: [{ field: "content_type", message: "File type not allowed. Allowed types: JPEG, PNG, GIF, WebP, PDF",
                     code: "INVALID_CONTENT_TYPE", }],
        }
      end

      if byte_size > MAX_FILE_SIZE
        return {
          direct_upload: nil,
          errors: [{ field: "byte_size", message: "File size must be less than 10MB", code: "FILE_TOO_LARGE" }],
        }
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
        errors: [],
      }
    end
  end
end
