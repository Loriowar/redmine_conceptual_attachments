class SmartUploadHandler < CommonUploadHandler
  require 'digest/md5'

  # self join
  has_many :upload_handlers_with_same_file,
           class_name: name,
           primary_key: :parametrized_attachment_id,
           foreign_key: :parametrized_attachment_id

  validate :file_uniqueness

  def with_same_container
    self.class.where(container_id: container_id,
                     container_type: container_type)
  end

  def same_attachment_ids
    self.class.where_digest(digest).pluck('attachments.id')
  end

  def attachment_multiple_usages?
    upload_handlers_with_same_file.count > 1
  end

private

  def digest
    unless @file.nil?
      if @file.respond_to? :digest
        @file.digest
      else
        @file.rewind
        # @todo: maybe better to generate a digest through a small buffer
        digest = Digest::MD5.hexdigest(@file.read)
        @file.rewind
        digest
      end
    end
  end

  # callbacks

  def create_attachment
    attachment_ids = same_attachment_ids
    if attachment_ids.many?
      logger.error{"Duplicated attachments for '#{self.class.name}' with digest='#{digest}'. Ids of attachments: #{same_attachment_ids.join(', ')}"}
      self.parametrized_attachment_id = attachment_ids.first
    elsif attachment_ids.one?
      self.parametrized_attachment_id = attachment_ids.first
    else
      super
    end
  end

  def destroy_attachment
    super unless attachment_multiple_usages?
  end

  # validations

  def file_uniqueness
    if with_same_container.joins(:parametrized_attachment).
        where(self.class.table_name => {filename: dynamic_filename},
              attachments: {digest: digest}).any?
      errors.add(:base, l(:file_with_same_content_and_name_already_exist,
                           scope: 'conceptual_attachment.errors',
                           filename: dynamic_filename))
    end

  end
end