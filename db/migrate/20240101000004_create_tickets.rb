# frozen_string_literal: true

class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets, id: :uuid do |t|
      t.string :subject, null: false
      t.text :description, null: false
      t.string :status, null: false, default: "new"
      t.uuid :customer_id, null: false
      t.uuid :assigned_agent_id
      t.datetime :closed_at

      t.timestamps
    end

    add_index :tickets, :customer_id
    add_index :tickets, :assigned_agent_id
    add_index :tickets, :status
    add_index :tickets, :created_at
    add_index :tickets, :updated_at
    add_index :tickets, [:status, :created_at]

    add_foreign_key :tickets, :customers, column: :customer_id
    add_foreign_key :tickets, :agents, column: :assigned_agent_id
  end
end
