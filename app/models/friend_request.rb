class FriendRequest < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :sender_id, presence: true
  validates :receiver_id, presence: true
  # Don't use uniqueness validation - we handle pending requests in cannot_request_if_pending_exists
  # This allows new requests after rejection/cancellation
  validate :cannot_request_self, on: :create
  validate :cannot_request_existing_friend, on: :create
  validate :cannot_request_if_pending_exists, on: :create

  enum status: {
    pending: 'pending',
    accepted: 'accepted',
    rejected: 'rejected',
    cancelled: 'cancelled'
  }

  scope :pending_requests, -> { where(status: 'pending') }
  scope :sent_by, ->(user) { where(sender_id: user.id) }
  scope :received_by, ->(user) { where(receiver_id: user.id) }

  private

  def cannot_request_self
    if sender_id == receiver_id
      errors.add(:receiver_id, "You cannot send a friend request to yourself")
    end
  end

  def cannot_request_existing_friend
    if sender && sender.friend_with?(receiver)
      errors.add(:receiver_id, "You are already friends with this user")
    end
  end

  def cannot_request_if_pending_exists
    # Check if there's already a pending request in EITHER direction
    existing = FriendRequest.where(
      "(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
      sender_id, receiver_id, receiver_id, sender_id
    ).where(status: 'pending')
     .where.not(id: id)
     .exists?

    if existing
      # Check which direction the existing request is
      from_me = FriendRequest.where(
        sender_id: sender_id,
        receiver_id: receiver_id,
        status: 'pending'
      ).where.not(id: id).exists?
      
      to_me = FriendRequest.where(
        sender_id: receiver_id,
        receiver_id: sender_id,
        status: 'pending'
      ).where.not(id: id).exists?

      if from_me
        errors.add(:base, "You have already sent a friend request to this user")
      elsif to_me
        errors.add(:base, "This user has already sent you a friend request. Check your Friend Requests tab.")
      else
        errors.add(:base, "A friend request already exists between you and this user")
      end
    end
  end
end

