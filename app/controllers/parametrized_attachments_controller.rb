class ParametrizedAttachmentsController < ApplicationController
  model_object ParametrizedAttachment

  prepend_before_filter :find_model_object

  def show
    filename = params[:filename] || @object.filename
    if @object.existed_filenames.include? filename
      send_file @object.diskfile,
                filename: filename_for_content_disposition(filename),
                type: detect_content_type(@object),
                disposition: (@object.image? ? 'inline' : 'attachment')
    else
      render_404
    end
  end

private

  # copypast from ApplicationController
  def detect_content_type(attachment)
    content_type = attachment.content_type
    if content_type.blank?
      content_type = Redmine::MimeType.of(attachment.filename)
    end
    content_type.to_s
  end
end
