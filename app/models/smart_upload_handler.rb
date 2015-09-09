class SmartUploadHandler < CommonUploadHandler
  require 'digest/md5'

  # self join
  has_many :same_upload_handlers,
           class_name: name,
           primary_key: :parametrized_attachment_id,
           foreign_key: :parametrized_attachment_id

  def same_attachment_ids
    self.class.joins(:parametrized_attachment).
        where(attachments: {digest: digest}).
        pluck('attachments.id')
  end

  def attachment_multiple_usages?
    same_upload_handlers.count > 1
  end

private

  def digest
    if @file.present?
      @file.rewind
      @digest = Digest::MD5.hexdigest(@file.read)
      @file.rewind
      @digest
    end
  end

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
end