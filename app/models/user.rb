class User < ApplicationRecord
  has_secure_password

  validates :username, presence: true, length: { minimum: 3, maximum: 10 },
                       uniqueness: { case_sensitive: false }

  has_many :messages, dependent: :destroy

  # friendships
  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships, source: :friend

  # reverse friendships (to find who added current user)
  has_many :inverse_friendships, class_name: "Friendship", foreign_key: "friend_id", dependent: :destroy
  has_many :followers, through: :inverse_friendships, source: :user

  # friend requests
  has_many :sent_friend_requests, class_name: "FriendRequest", foreign_key: "sender_id", dependent: :destroy
  has_many :received_friend_requests, class_name: "FriendRequest", foreign_key: "receiver_id", dependent: :destroy

  # conversations (as sender or receiver)
  has_many :sent_conversations, class_name: "Conversation", foreign_key: "sender_id", dependent: :destroy
  has_many :received_conversations, class_name: "Conversation", foreign_key: "receiver_id", dependent: :destroy

  # convenience: all conversations
  def conversations
    Conversation.where("sender_id = ? OR receiver_id = ?", id, id)
  end

  # friends? helper
  def friend_with?(other_user)
    friends.exists?(id: other_user.id)
  end
end

