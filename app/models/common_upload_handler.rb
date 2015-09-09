class CommonUploadHandler < BaseUploadHandler

  def self.target_directory
    "#{super}/#{name.underscore}/#{DateTime.now.strftime('%Y/%m')}"
  end

  def target_directory
    self.class.target_directory
  end

private

  def create_attachment
    new_attachment =
        ParametrizedAttachment.create(target_directory: target_directory,
                                      container_type: self.class.name,
                                      file: @file,
                                      author: User.current)
    if new_attachment.errors.any?
      logger.error{"Fail to save ParametrizedAttachment:\n#{new_attachment.errors.full_messages.join("\n")}"}
      errors.add(:base, l(:unable_to_save_attachment, scope: 'conceptual_attachment.errors'))
      # return false to break a callback chain
      false
    else
      self.parametrized_attachment = new_attachment
    end
  end

  def destroy_attachment
    parametrized_attachment.destroy
  end

end