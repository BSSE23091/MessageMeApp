class FriendshipsController < ApplicationController
  before_action :require_user

  # Note: create action removed - friendships are now created through friend requests
  # This method is kept for backwards compatibility but should not be accessible via routes

  def destroy
    friend = User.find(params[:id])
    friendship = current_user.friendships.find_by(friend_id: friend.id)
    
    unless friendship
      redirect_back fallback_location: chatroom_path, alert: "Friendship not found."
      return
    end

    # Use transaction to ensure all cleanup happens atomically
    ActiveRecord::Base.transaction do
      # Find and delete bidirectional friendship
      reverse_friendship = friend.friendships.find_by(friend_id: current_user.id)
      
      # Delete both friendships (bidirectional)
      friendship.destroy
      reverse_friendship&.destroy

      # Find and delete the conversation between them (if exists)
      conversation = Conversation.between(current_user.id, friend.id)
      if conversation
        # This will also delete all messages in the conversation (dependent: :destroy)
        conversation.destroy
      end

      # Also delete any DM messages directly between them (safety check)
      # This handles edge cases where messages might not be in a conversation
      # Note: This shouldn't happen in normal flow, but good to clean up
      Message.where(conversation_id: nil)
             .where(user_id: [current_user.id, friend.id])
             .delete_all

      # Clean up ALL friend requests between them (not just pending)
      FriendRequest.where(
        "(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
        current_user.id, friend.id, friend.id, current_user.id
      ).destroy_all
    end

    redirect_back fallback_location: chatroom_path, notice: "#{friend.username} has been removed from your friends list. All messages and conversations have been deleted."
  end
end
