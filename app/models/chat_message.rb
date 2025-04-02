class ChatMessage < ApplicationRecord
  belongs_to :document

  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: %w[user assistant] }

  scope :chronological, -> { order(created_at: :asc) }
end 