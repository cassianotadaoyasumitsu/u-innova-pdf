class DocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document, only: [:show, :destroy]
  before_action :authorize_document, only: [:show, :destroy]

  def index
    @documents = current_user.documents.order(created_at: :desc)
  end

  def show
    @chat_messages = @document.chat_messages.chronological
  end

  def new
    @document = current_user.documents.build
  end

  def create
    @document = current_user.documents.build(document_params)
    
    if params[:document][:pdf_file].present?
      pdf_file = params[:document][:pdf_file]
      reader = PDF::Reader.new(pdf_file.tempfile)
      @document.content = reader.pages.map(&:text).join("\n")
    end

    if @document.save
      @document.pdf_file.attach(params[:document][:pdf_file])
      redirect_to @document, notice: 'Documento foi criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy
    redirect_to documents_url, notice: 'Documento foi excluído com sucesso.'
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def authorize_document
    unless @document.user == current_user
      redirect_to documents_path, alert: 'Você não está autorizado a acessar este documento.'
    end
  end

  def document_params
    params.require(:document).permit(:title, :pdf_file, :content)
  end
end
  