class RedmineConceptualAttachments::StorageWrappers::Attachment
  # class for wrapping an Attachment instance for using in copy action of UploadHandler
  # minimal interface:
  #   def size()
  #   def digest()
  #   def content_type()
  #   def original_filename()
  #   def read(length) or to_str()

  # options must contain follows keys: :object
  def initialize(options)
    @object = options[:object]
    @custom_file_name = options[:file_name]
    raise ArgumentError, 'Argument must be an Attachment object' unless @object.is_a? Attachment

    @file = File.open(disk_file_path, 'rb')

    # GC must do this work
    # ObjectSpace.define_finalizer( self, ->{finalize} )
  end

  def size
    @object.filesize
  end

  def digest
    @object.digest
  end

  def content_type
    @object.content_type
  end

  def original_filename
    @custom_file_name || @object.filename
  end

  def read(length)
    @file.read(length)
  end

  def rewind
    @file.rewind
  end

  # destructor
  # def finalize
  #   @file.close unless @file.closed?
  # end

private

  def disk_file_path
    @object.diskfile
  end

end
