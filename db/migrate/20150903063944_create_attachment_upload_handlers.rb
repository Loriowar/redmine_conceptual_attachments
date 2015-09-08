class CreateAttachmentUploadHandlers < ActiveRecord::Migration
  def change
    create_table :attachment_upload_handlers do |t|
      t.string     :type
      t.string     :filename
      t.references :container, polymorphic: true
      t.references :parametrized_attachment
      t.integer    :created_by_id
      t.integer    :updated_by_id
      t.timestamps
    end

    add_index :attachment_upload_handlers, :type
    add_index :attachment_upload_handlers, :parametrized_attachment_id
    add_index :attachment_upload_handlers, %i(container_id container_type),
              name: 'index_attachment_upload_handlers_on_container'
  end
end
