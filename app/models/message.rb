class Message < ApplicationRecord
  belongs_to :user
  belongs_to :conversation, optional: true
  
  validates :body, presence: true
end
