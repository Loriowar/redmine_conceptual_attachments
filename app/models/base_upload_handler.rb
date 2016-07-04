class BaseUploadHandler < ActiveRecord::Base
  self.abstract_class = true
  self.table_name = 'attachment_upload_handlers'

  class_attribute :copy_operation
  self.copy_operation = RedmineConceptualAttachments::Operations::Copy

  attr_accessor :file,
                :custom_filename,
                :available_extensions,
                :available_content_types

  belongs_to :container, polymorphic: true
  belongs_to :parametrized_attachment
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

  validates_presence_of :file, if: ->{ parametrized_attachment_id.blank? }
  validates_presence_of :container
  validate :filename_presence
  validate :check_max_file_size
  validate :check_extension
  validate :check_content_type

  before_create  :fill_default
  before_update  :set_updater
  before_save    :fill_obligates
  before_save    :create_attachment
  before_destroy :destroy_attachment

  scope :within_current_class, -> do
    where(self.table_name => {type: name})
  end

  scope :where_container, ->(obj) do
      where(container_id: obj.id,
            container_type: obj.class.name)
  end

  scope :where_digest, ->(digest) do
      joins(:parametrized_attachment).
          where(attachments: {digest: digest})
  end

  class << self
    def target_directory
      'parametrized_attachments'
    end

    # skip filesize validation by default
    def max_file_size
      0
    end
  end

  def target_directory
    self.class.target_directory
  end

  def max_file_size
    self.class.max_file_size
  end

  def filesize
    if @file.respond_to?(:size)
      @file.size
    elsif parametrized_attachment.present?
      parametrized_attachment.filesize
    end
  end

  def content_type
    if @file.respond_to?(:content_type)
      @file.content_type.to_s.chomp
    elsif parametrized_attachment.present?
      parametrized_attachment.content_type
    end
  end

  def extension
    if dynamic_filename.include?('.')
      dynamic_filename.split('.').last.underscore
    end
  end

  # read only attachment record with filled custom values
  def attachment_representation
    parametrized_attachment.tap do |attachment|
      %w(filename target_directory max_file_size).each do |attr|
        attachment.public_send("#{attr}=", public_send(attr))
      end
      attachment.readonly!
    end
  end

  def dynamic_filename
    if custom_filename.present?
      custom_filename
    elsif @file.respond_to?(:original_filename)
      @file.original_filename
    elsif filename.present?
      filename
    else
      # @todo: maybe here must be an exception or log information
    end
  end

private

  # copy interface

  # @deprecated
  def same_upload_handler?(upload_handler)
    upload_handler.instance_of? self.class
  end

  # callbacks

  def fill_default
    self.created_by = User.current
  end

  def fill_obligates
    self.filename = dynamic_filename
  end

  def set_updater
    self.updated_by = User.current
  end

  def create_attachment
    raise NotImplementedError, 'Must be implemented in subclasses'
  end

  def destroy_attachment
    raise NotImplementedError, 'Must be implemented in subclasses'
  end

  # validations

  def filename_presence
    if dynamic_filename.blank?
      errors.add(:base, l(:unable_to_obtain_filename, scope: 'conceptual_attachment.errors'))
    end
  end

  def check_max_file_size
    if max_file_size.nonzero? && filesize.to_i > max_file_size
      errors.add(:base, l(:error_attachment_too_big, max_size: max_file_size))
    end
  end

  def check_extension
    if @available_extensions.to_a.any? && @available_extensions.to_a.exclude?(extension)
      errors.add(:base, l(:invalid_extension_with_allowed_only_list,
                          scope: 'conceptual_attachment.errors',
                          extension: extension,
                          available_extensions: @available_extensions.join(', ')))
    end
  end

  def check_content_type
    if @available_content_types.to_a.any? && @available_content_types.to_a.exclude?(extension)
      errors.add(:base, l(:invalid_content_type,
                          scope: 'conceptual_attachment.errors',
                          content_type: content_type))
    end
  end
end