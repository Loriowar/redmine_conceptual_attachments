module RedmineConceptualAttachments::ApplicationHelperPatch
  extend ActiveSupport::Concern

  included do
    def link_to_parametrized_attachment(attachment, options={})
      text = options.delete(:text) || attachment.filename
      # @todo: implement same behaviour as attachment if needed
      _route_method = options.delete(:download)
      html_options = options.slice!(:only_path)
      url = named_parametrized_attachment_path(options.merge({id: attachment.id, filename: attachment.filename}))
      link_to text, url, html_options
    end

    def link_to_any_attachment(attachment, options={})
      if attachment.is_a? ParametrizedAttachment
        link_to_parametrized_attachment(attachment, options)
      else
        link_to_attachment(attachment, options)
      end
    end
  end

  #instance methods were here

  module ClassMethods
    #class methods were here
  end
end