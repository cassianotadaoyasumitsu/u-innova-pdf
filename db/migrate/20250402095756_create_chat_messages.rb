class CreateChatMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_messages do |t|
      t.references :document, null: false, foreign_key: true
      t.text :content, null: false
      t.string :role, null: false

      t.timestamps
    end
  end
end 