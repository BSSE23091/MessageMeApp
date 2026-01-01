class CreateFriendRequests < ActiveRecord::Migration[6.1]
  # Use explicit up/down with safety checks so a partially‑applied migration
  # (like the one you just hit) can be re-run without blowing up.
  def up
    unless table_exists?(:friend_requests)
      create_table :friend_requests do |t|
        t.references :sender, null: false, foreign_key: { to_table: :users }
        t.references :receiver, null: false, foreign_key: { to_table: :users }
        t.string :status, default: "pending", null: false
        t.timestamps
      end
    end

    # Unique sender/receiver pair
    unless index_exists?(:friend_requests, [:sender_id, :receiver_id])
      add_index :friend_requests, [:sender_id, :receiver_id], unique: true
    end

    # Status index for quick lookups
    unless index_exists?(:friend_requests, :status)
      add_index :friend_requests, :status
    end
  end

  def down
    drop_table :friend_requests, if_exists: true
  end
end

