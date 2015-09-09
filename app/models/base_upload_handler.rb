class BaseUploadHandler < ActiveRecord::Base
  self.abstract_class = true
  self.table_name = 'attachment_upload_handlers'

  attr_accessor :file, :custom_filename

  belongs_to :container, polymorphic: true
  belongs_to :parametrized_attachment
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

  validates_presence_of :file, :container

  before_create  :fill_default
  before_update  :set_updater
  before_save    :fill_obligates
  before_save    :create_attachment
  before_destroy :destroy_attachment

  scope :where_container, ->(obj) do
    where(container_id: obj.id, container_type: obj.class.name)
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

  # read only attachment record with filled custom values
  def attachment_representation
    parametrized_attachment.tap do |attachment|
      %w(filename target_directory max_file_size).each do |attr|
        attachment.public_send("#{attr}=", public_send(attr))
      end
      attachment.readonly!
    end
  end

private

  # callbacks

  def fill_default
    self.created_by = User.current
  end

  def fill_obligates
    if custom_filename.present?
      self.filename = custom_filename
    elsif @file.respond_to?(:original_filename)
      self.filename = @file.original_filename
    else
      errors.add(:base, l(:unable_to_obtain_filename, scope: 'conceptual_attachment.errors'))
      # return false to break a callback chain
      false
    end
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
end