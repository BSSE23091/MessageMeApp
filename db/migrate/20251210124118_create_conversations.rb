class CreateConversations < ActiveRecord::Migration[6.1]
  def change
    create_table :conversations do |t|
      t.integer :sender_id, null: false, index: true
      t.integer :receiver_id, null: false, index: true
      t.timestamps
    end

    add_index :conversations, [:sender_id, :receiver_id], unique: true
  end
end
