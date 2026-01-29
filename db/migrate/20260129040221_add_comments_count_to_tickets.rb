class AddCommentsCountToTickets < ActiveRecord::Migration[7.2]
  def change
    add_column :tickets, :comments_count, :integer, default: 0, null: false

    # Backfill existing counts
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE tickets
          SET comments_count = (
            SELECT COUNT(*) FROM comments WHERE comments.ticket_id = tickets.id
          )
        SQL
      end
    end
  end
end
