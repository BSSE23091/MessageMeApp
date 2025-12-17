class FriendshipsController < ApplicationController
  before_action :require_user

  def create
    friend = User.find(params[:friend_id])
    if current_user == friend
      redirect_back fallback_location: chatroom_path, alert: "You can't add yourself."
      return
    end

    friendship = current_user.friendships.build(friend: friend)
    if friendship.save
      redirect_back fallback_location: chatroom_path, notice: "Added #{friend.username} as a friend."
    else
      redirect_back fallback_location: chatroom_path, alert: friendship.errors.full_messages.to_sentence
    end
  end

  def destroy
    friendship = current_user.friendships.find_by(friend_id: params[:id])
    if friendship&.destroy
      redirect_back fallback_location: chatroom_path, notice: "Friend removed."
    else
      redirect_back fallback_location: chatroom_path, alert: "Could not remove friend."
    end
  end
end
