# frozen_string_literal: true

class CreateRefreshTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :refresh_tokens, id: :uuid do |t|
      t.string :token_digest, null: false
      t.string :user_type, null: false
      t.uuid :user_id, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :refresh_tokens, :token_digest, unique: true
    add_index :refresh_tokens, [:user_type, :user_id]
    add_index :refresh_tokens, :expires_at
  end
end
