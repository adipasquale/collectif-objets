# frozen_string_literal: true

module MessagesControllerConcern
  extend ActiveSupport::Concern

  def index
    @new_message = Message.new(commune: @commune)
  end

  def create
    @message = Message.new(message_params)
    authorize @message
    return render_index_after_create_error unless @message.save

    @message.enqueue_message_received_emails
    respond_to do |format|
      format.html { redirect_to after_create_path }
      format.turbo_stream
    end
  end

  protected

  def message_params
    params
      .require(:message)
      .permit(:text, files: [])
      .merge(origin: "web", commune_id: @commune.id, author: new_message_author)
  end

  def render_index_after_create_error
    set_messages
    @new_message = @message
    render :index, status: :unprocessable_content
  end
end
