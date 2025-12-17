class MessagesController < ApplicationController
  before_action :require_user

  def create
    # If DM (conversation_id present - from nested route or param)
    if params[:conversation_id].present?
      conversation = Conversation.find(params[:conversation_id])

      # Ensure only participants can send messages
      unless [conversation.sender_id, conversation.receiver_id].include?(current_user.id)
        redirect_back fallback_location: conversations_path, alert: "You are not allowed to send messages in this conversation."
        return
      end

      other = conversation.sender_id == current_user.id ? conversation.receiver : conversation.sender
      unless current_user.friend_with?(other)
        redirect_back fallback_location: chatroom_path(tab: 'messages'), alert: "You are no longer friends with that user."
        return
      end

      @message = conversation.messages.build(message_params)
      @message.user = current_user

      if @message.save
        redirect_to conversation_path(conversation), notice: "Message sent!"
      else
        redirect_to conversation_path(conversation), alert: @message.errors.full_messages.to_sentence
      end

    else
      # Otherwise: global chatroom message
      @message = current_user.messages.build(message_params)

      if @message.save
        redirect_to chatroom_path, notice: "Message sent!"
      else
        redirect_to chatroom_path, alert: @message.errors.full_messages.to_sentence
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end
