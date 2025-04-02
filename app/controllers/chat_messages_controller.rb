class ChatMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document
  before_action :authorize_document

  def create
    @chat_message = @document.chat_messages.build(chat_message_params)
    @chat_message.role = 'user'

    if @chat_message.save
      # TODO: Add AI response logic here
      # For now, we'll just create a placeholder response
      @document.chat_messages.create!(
        content: "Olá! Sou seu assistente IA. Como posso ajudar você com este documento?",
        role: 'assistant'
      )
    end

    redirect_to @document
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end

  def authorize_document
    unless @document.user == current_user
      redirect_to documents_path, alert: 'Você não está autorizado a acessar este documento.'
    end
  end

  def chat_message_params
    params.require(:chat_message).permit(:content)
  end
end 