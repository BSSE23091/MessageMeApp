class AddConversationToMessages < ActiveRecord::Migration[6.1]
  def change
    add_reference :messages, :conversation, foreign_key: true, index: true, null: true
  end
end
