# frozen_string_literal: true

class CreateAgents < ActiveRecord::Migration[7.1]
  def change
    create_table :agents, id: :uuid do |t|
      ## Devise fields
      t.citext :email, null: false
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip

      ## Invitable
      t.string :invitation_token
      t.datetime :invitation_created_at
      t.datetime :invitation_sent_at
      t.datetime :invitation_accepted_at
      t.integer :invitation_limit
      t.uuid :invited_by_id
      t.string :invited_by_type
      t.integer :invitations_count, default: 0

      ## Custom fields
      t.string :name, null: false
      t.boolean :is_admin, default: false, null: false
      t.datetime :last_assigned_at

      t.timestamps
    end

    add_index :agents, :email, unique: true
    add_index :agents, :reset_password_token, unique: true
    add_index :agents, :invitation_token, unique: true
    add_index :agents, :invited_by_id
    add_index :agents, :last_assigned_at
  end
end
