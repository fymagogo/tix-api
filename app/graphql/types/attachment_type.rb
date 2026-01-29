# frozen_string_literal: true

module Types
  class AttachmentType < Types::BaseObject
    description "A file attachment"

    field :id, ID, null: false
    field :filename, String, null: false
    field :content_type, String, null: false
    field :byte_size, Integer, null: false
    field :url, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false

    def id
      object.id.to_s
    end

    def url
      Rails.application.routes.url_helpers.rails_blob_url(object)
    end

    def created_at
      object.created_at
    end
  end
end
