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
  require_patch plugin_name, %w(attachment)
end

ActiveRecord::Base.send(:include, RedmineConceptualAttachments::UploadHandler)
