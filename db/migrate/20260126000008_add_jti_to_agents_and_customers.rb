# frozen_string_literal: true

class AddJtiToAgentsAndCustomers < ActiveRecord::Migration[7.1]
  def change
    add_column :agents, :jti, :string, null: false, default: -> { "gen_random_uuid()::text" }
    add_column :customers, :jti, :string, null: false, default: -> { "gen_random_uuid()::text" }

    add_index :agents, :jti
    add_index :customers, :jti
  end
end
