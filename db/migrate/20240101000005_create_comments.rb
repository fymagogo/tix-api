# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments, id: :uuid do |t|
      t.text :body, null: false
      t.uuid :ticket_id, null: false
      t.uuid :author_id, null: false
      t.string :author_type, null: false

      t.timestamps
    end

    add_index :comments, :ticket_id
    add_index :comments, [:author_type, :author_id]
    add_index :comments, [:ticket_id, :created_at]

    add_foreign_key :comments, :tickets, column: :ticket_id
  end
end
