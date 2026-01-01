class ChatroomChannel < ApplicationCable::Channel
  # Global chat + optional per-conversation streams

  def subscribed
    if params[:conversation_id].present?
      conversation_id = params[:conversation_id].to_i
      conversation = Conversation.find_by(id: conversation_id)

      # Only allow participants of the conversation to subscribe
      if conversation && [conversation.sender_id, conversation.receiver_id].include?(current_user.id)
        stream_for conversation
        Rails.logger.info "User #{current_user.id} subscribed to conversation #{conversation_id}"
      else
        Rails.logger.warn "Subscription rejected: User #{current_user&.id} tried to subscribe to conversation #{conversation_id}"
        reject
      end
    else
      # Global chat stream
      stream_from "chatroom_global"
      Rails.logger.info "User #{current_user.id} subscribed to global chat"
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end