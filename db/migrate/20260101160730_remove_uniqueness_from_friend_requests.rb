class RemoveUniquenessFromFriendRequests < ActiveRecord::Migration[6.1]
  def change
    # Remove the unique index
    remove_index :friend_requests, [:sender_id, :receiver_id], if_exists: true
    
    # Add a non-unique index for query performance
    add_index :friend_requests, [:sender_id, :receiver_id], if_not_exists: true
    
    # Add unique index for pending requests only (partial index)
    # Note: SQLite doesn't support partial indexes well, so we'll enforce this in the model
  end
end
