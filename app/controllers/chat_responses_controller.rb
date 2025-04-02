class ChatResponsesController < ApplicationController
  include ActionController::Live
  before_action :authenticate_user!
  before_action :set_document
  before_action :authorize_document

  MAX_CONTEXT_LENGTH = 8000 # Ajustado para o GPT-4

  def show
    response.headers['Content-Type']  = 'text/event-stream'
    response.headers['Last-Modified'] = Time.now.httpdate
    sse                               = SSE.new(response.stream, event: "message")
    
    # Log API key presence (but not the key itself)
    Rails.logger.info "OpenAI API key present: #{ENV['OPENAI_ACCESS_TOKEN'].present?}"
    Rails.logger.info "Document content length: #{@document.content&.length || 0}"
    
    client = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])

    # Save user message
    user_message = @document.chat_messages.create!(
      role: 'user',
      content: params[:prompt],
      document_id: @document.id
    )
    Rails.logger.info "Saved user message: #{user_message.id}"

    begin
      assistant_response = ""
      Rails.logger.info "Starting OpenAI API call with model: gpt-4"
      
      # Prepare the context from the document content
      context = @document.content.presence || "No content available in the document."
      
      # Limitar o tamanho do contexto
      if context.length > MAX_CONTEXT_LENGTH
        Rails.logger.info "Context too long, truncating to #{MAX_CONTEXT_LENGTH} characters"
        context = context[0..MAX_CONTEXT_LENGTH] + "..."
      end
      
      Rails.logger.info "Final context length: #{context.length}"
      
      # Log the messages being sent to OpenAI
      messages = [
        { 
          role: "system", 
          content: "You are a helpful assistant that answers questions about the provided PDF document. Use the following context to answer questions: #{context}" 
        },
        { role: "user", content: params[:prompt] }
      ]
      Rails.logger.info "Messages being sent to OpenAI: #{messages.inspect}"
      
      client.chat(
        parameters: {
          model:    "gpt-4",
          messages: messages,
          stream:   proc do |chunk|
            content = chunk.dig("choices", 0, "delta", "content")
            next if content.nil?
            
            assistant_response += content
            Rails.logger.info "Streaming content: #{content}"
            sse.write({
              message: content,
            })
          end
        }
      )

      # Save assistant's complete response
      if assistant_response.present?
        Rails.logger.info "Saving assistant response: #{assistant_response.length} characters"
        assistant_message = @document.chat_messages.create!(
          role: 'assistant',
          content: assistant_response,
          document_id: @document.id
        )
        Rails.logger.info "Saved assistant message: #{assistant_message.id}"
      else
        Rails.logger.warn "No assistant response to save"
      end
    rescue OpenAI::Error => e
      Rails.logger.error "OpenAI API Error: #{e.message}"
      Rails.logger.error "Error type: #{e.class}"
      Rails.logger.error e.backtrace.join("\n")
      sse.write({ message: "Error: #{e.message}" })
    rescue => e
      Rails.logger.error "Chat response error: #{e.message}"
      Rails.logger.error "Error type: #{e.class}"
      Rails.logger.error e.backtrace.join("\n")
      sse.write({ message: "Error: #{e.message}" })
    ensure
      sse.close
    end
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end

  def authorize_document
    unless @document.user == current_user
      redirect_to documents_path, alert: 'You are not authorized to access this document.'
    end
  end
end 