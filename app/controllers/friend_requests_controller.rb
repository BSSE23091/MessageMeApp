class FriendRequestsController < ApplicationController
  before_action :require_user

  def create
    receiver = User.find(params[:receiver_id])
    
    # Check if already friends
    if current_user.friend_with?(receiver)
      redirect_back fallback_location: chatroom_path(tab: 'users'), alert: "You are already friends with #{receiver.username}."
      return
    end

    # Check for any existing pending requests in either direction
    existing_request = FriendRequest.where(
      "(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
      current_user.id, receiver.id, receiver.id, current_user.id
    ).where(status: 'pending').first

    if existing_request
      if existing_request.sender_id == current_user.id
        # Current user already sent a request
        redirect_back fallback_location: chatroom_path(tab: 'users'), alert: "You have already sent a friend request to #{receiver.username}. Check your Friend Requests tab to cancel it."
      else
        # Receiver already sent a request to current user
        redirect_back fallback_location: chatroom_path(tab: 'users'), alert: "#{receiver.username} has already sent you a friend request. Check your Friend Requests tab to accept or reject it."
      end
      return
    end

    @friend_request = current_user.sent_friend_requests.build(receiver: receiver)

    if @friend_request.save
      # Broadcast notification to receiver
      broadcast_friend_request_notification(@friend_request)
      
      respond_to do |format|
        format.html { redirect_back fallback_location: chatroom_path(tab: 'users'), notice: "Friend request sent to #{receiver.username}." }
        format.js   { head :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: chatroom_path(tab: 'users'), alert: @friend_request.errors.full_messages.to_sentence }
        format.js   { render json: { errors: @friend_request.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def accept
    @friend_request = current_user.received_friend_requests.find(params[:id])
    
    unless @friend_request.pending?
      redirect_back fallback_location: chatroom_path(tab: 'friend_requests'), alert: "This friend request has already been processed."
      return
    end

    # Use transaction to ensure both friendship creation and status update happen together
    ActiveRecord::Base.transaction do
      # Check if friendship already exists (shouldn't happen, but safety check)
      unless @friend_request.sender.friend_with?(@friend_request.receiver)
        # Create bidirectional friendship
        Friendship.find_or_create_by(user: @friend_request.sender, friend: @friend_request.receiver)
        Friendship.find_or_create_by(user: @friend_request.receiver, friend: @friend_request.sender)
      end

      # Update this request to accepted
      @friend_request.update!(status: 'accepted')
      
      # Also update any reverse request (if receiver had sent one to sender)
      reverse_request = FriendRequest.where(
        sender_id: @friend_request.receiver_id,
        receiver_id: @friend_request.sender_id,
        status: 'pending'
      ).first
      
      if reverse_request
        reverse_request.update!(status: 'accepted')
      end
    end

    # Reload to ensure fresh data
    @friend_request.reload

    # Broadcast notification to sender
    broadcast_friend_request_accepted(@friend_request)

    respond_to do |format|
      format.html { redirect_to chatroom_path(tab: 'friend_requests'), notice: "You are now friends with #{@friend_request.sender.username}!" }
      format.js   { head :ok }
    end
  end

  def reject
    @friend_request = current_user.received_friend_requests.find(params[:id])
    
    unless @friend_request.pending?
      redirect_back fallback_location: chatroom_path(tab: 'friend_requests'), alert: "This friend request has already been processed."
      return
    end

    @friend_request.update!(status: 'rejected')

    respond_to do |format|
      format.html { redirect_to chatroom_path(tab: 'friend_requests'), notice: "Friend request from #{@friend_request.sender.username} rejected." }
      format.js   { head :ok }
    end
  end

  def cancel
    @friend_request = current_user.sent_friend_requests.find(params[:id])
    
    unless @friend_request.pending?
      redirect_back fallback_location: chatroom_path(tab: 'friend_requests'), alert: "This friend request has already been processed."
      return
    end

    @friend_request.update!(status: 'cancelled')

    respond_to do |format|
      format.html { redirect_to chatroom_path(tab: 'friend_requests'), notice: "Friend request cancelled." }
      format.js   { head :ok }
    end
  end

  private

  def broadcast_friend_request_notification(friend_request)
    # Broadcast to receiver's notification channel
    NotificationChannel.broadcast_to(
      friend_request.receiver,
      {
        type: 'friend_request',
        message: "#{friend_request.sender.username} sent you a friend request",
        friend_request_id: friend_request.id,
        sender_id: friend_request.sender.id,
        sender_username: friend_request.sender.username
      }
    )
  end

  def broadcast_friend_request_accepted(friend_request)
    # Broadcast to sender that their request was accepted
    NotificationChannel.broadcast_to(
      friend_request.sender,
      {
        type: 'friend_request_accepted',
        message: "#{friend_request.receiver.username} accepted your friend request",
        receiver_id: friend_request.receiver.id,
        receiver_username: friend_request.receiver.username
      }
    )
  end
end

