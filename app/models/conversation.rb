class Conversation < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  has_many :messages, dependent: :destroy

  validates :sender_id, presence: true
  validates :receiver_id, presence: true
  validates :sender_id, uniqueness: { scope: :receiver_id }

  # find existing conversation between two users regardless of order
  def self.between(user_a_id, user_b_id)
    where(sender_id: user_a_id, receiver_id: user_b_id)
      .or(where(sender_id: user_b_id, receiver_id: user_a_id))
      .first
  end

  # find or create conversation (returns conversation)
  def self.find_or_create_between(user_a, user_b)
    convo = between(user_a.id, user_b.id)
    return convo if convo.present?

    # create with smaller id as sender for uniqueness
    create!(sender: user_a, receiver: user_b)
  end
end
