plugin_name = :redmine_conceptual_attachments

Redmine::Plugin.register plugin_name do
  name 'Redmine Conceptual Attachments'
  author 'ELINS'
  description 'This is a plugin for Redmine'
  version RedmineConceptualAttachments::VERSION
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end

Rails.configuration.to_prepare do
  require_patch plugin_name, %w(attachment application_helper)
end

ActiveRecord::Base.send(:include, RedmineConceptualAttachments::UploadHandler)

# @note: all StorageWrappers must be required, otherwise autosearch StorageWrappers will be broken
require_dependency 'redmine_conceptual_attachments/storage_wrappers/attachment'
require_dependency 'redmine_conceptual_attachments/storage_wrappers/base_upload_handler'