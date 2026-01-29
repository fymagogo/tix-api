# frozen_string_literal: true

class AddTicketNumberToTickets < ActiveRecord::Migration[7.1]
  def change
    add_column :tickets, :ticket_number, :string, null: false
    add_index :tickets, :ticket_number, unique: true
  end
end
