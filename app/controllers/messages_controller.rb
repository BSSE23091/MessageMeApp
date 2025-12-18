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
        # Broadcast to conversation stream
        rendered_message = render_to_string(
          partial: "messages/message",
          locals: { message: @message }
        )

        # Use explicit hash argument so Ruby treats this as 2 positional args
        ChatroomChannel.broadcast_to(conversation, { html: rendered_message })
        Rails.logger.info "Broadcasted DM message to conversation #{conversation.id}"

        respond_to do |format|
          format.html { redirect_to conversation_path(conversation) }
          format.js   { head :ok }
        end
      else
        respond_to do |format|
          format.html { redirect_to conversation_path(conversation), alert: @message.errors.full_messages.to_sentence }
          format.js   { render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity }
        end
      end

    else
      # Otherwise: global chatroom message
      @message = current_user.messages.build(message_params)

      if @message.save
        # Broadcast to global chat stream
        rendered_message = render_to_string(
          partial: "messages/message",
          locals: { message: @message }
        )

        # Use explicit hash argument so Ruby treats this as 2 positional args
        ActionCable.server.broadcast("chatroom_global", { html: rendered_message })

        respond_to do |format|
          format.html { redirect_to chatroom_path }
          format.js   { head :ok }
        end
      else
        respond_to do |format|
          format.html { redirect_to chatroom_path, alert: @message.errors.full_messages.to_sentence }
          format.js   { render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end
