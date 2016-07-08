class RedmineConceptualAttachments::StorageWrappers::BaseUploadHandler
  # class for wrapping an *UploadHandler instance for using in copy action of UploadHandler
  # minimal interface:
  #   def size()
  #   def digest()
  #   def content_type()
  #   def original_filename()
  #   def read(length) or to_str()

  # options must contain follows keys: :object
  def initialize(options)
    @object = options[:object]
    raise ArgumentError, 'Argument must be an BaseUploadHandler object' unless @object.is_a? BaseUploadHandler

    @wrapper =
        RedmineConceptualAttachments::StorageWrappers::Attachment.new(object: parametrized_attachment,
                                                                      file_name: @object.dynamic_filename)
  end

  delegate :size, :digest, :content_type, :original_filename, :read, to: :wrapper, allow_nil: false, prefix: false

private

  attr_reader :wrapper

  def parametrized_attachment
    @object.parametrized_attachment
  end
end
