class Document < ApplicationRecord
  belongs_to :user
  
  has_one_attached :pdf_file
  has_many :chat_messages, dependent: :destroy
  
  validates :pdf_file, content_type: ['application/pdf']
  validates :pdf_file, size: { less_than: 10.megabytes, message: 'must be less than 10MB' }
end
