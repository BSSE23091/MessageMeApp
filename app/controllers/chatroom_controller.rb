class ChatroomController < ApplicationController
  before_action :require_user

  def index
    # Global chat - only show messages that are NOT part of a conversation (conversation_id is nil)
    @messages = Message.where(conversation_id: nil).includes(:user).order(created_at: :asc)

    # All users (for "Users" tab)
    @users = User.where.not(id: current_user.id)

    # Friends (for "Friends" tab)
    @friends = current_user.friends

    # Conversations (for "Messages" tab)
    @conversations = current_user.conversations
                                   .includes(:sender, :receiver)
                                   .order(updated_at: :desc)
                                   .select { |convo| current_user.friend_with?(convo.sender_id == current_user.id ? convo.receiver : convo.sender) }
  end
end
