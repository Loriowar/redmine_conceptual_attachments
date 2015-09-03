class ParametrizedAttachment < Attachment

  alias default_target_directory target_directory

  attr_reader :max_file_size, :filename, :target_directory

  after_initialize :fill_default

  # attr_writers

  def max_file_size=(val)
    @max_file_size = val.to_i.zero? ? Setting.attachment_max_size.to_i.kilobytes : val.to_i
  end

  def filename=(val)
    sanitized_filename = sanitize_filename(val.to_s)
    @filename = sanitized_filename if sanitized_filename.present?
    super(@filename)
  end

  def target_directory=(val)
    # @todo: need to sanitize val
    sanitized_target_directory = val.to_s
    @target_directory = sanitized_target_directory if sanitized_target_directory.present?
    @target_directory
  end

  # validations

  def validate_max_file_size
    if @temp_file && self.filesize > @max_file_size
      errors.add(:base, l(:error_attachment_too_big, :max_size => @max_file_size))
    end
  end

  # callbacks

  def fill_default
    @max_file_size ||= Setting.attachment_max_size.to_i.kilobytes
    @filename ||= read_attribute(:filename)
    @target_directory ||= default_target_directory
  end

end