class ConversationsController < ApplicationController
  before_action :require_user

  def index
    # show user's conversation list
    @conversations = current_user.conversations
                                 .includes(:sender, :receiver)
                                 .order(updated_at: :desc)
                                 .select { |convo| current_user.friend_with?(convo.sender_id == current_user.id ? convo.receiver : convo.sender) }
  end

  def show
    @conversation = Conversation.find(params[:id])

    # ensure current_user is part of conversation
    unless [@conversation.sender_id, @conversation.receiver_id].include?(current_user.id)
      redirect_to conversations_path, alert: "You are not authorized to view that conversation."
      return
    end

    other = @conversation.sender_id == current_user.id ? @conversation.receiver : @conversation.sender
    unless current_user.friend_with?(other)
      redirect_to conversations_path, alert: "You are no longer friends with that user."
      return
    end

    @messages = @conversation.messages.includes(:user).order(created_at: :asc)
    @message = Message.new
  end

  def create
    other = User.find(params[:user_id])

    unless current_user.friend_with?(other)
      redirect_back fallback_location: chatroom_path, alert: "You can only start conversations with friends."
      return
    end

    convo = Conversation.find_or_create_between(current_user, other)
    redirect_to conversation_path(convo)
  end
end
