class RedmineConceptualAttachments::Operations::Copy
  def initialize(options)
    @from = options[:from]
    @wrapper_class = options[:wrapper_class]
    @wrapper_class = @wrapper_class.constantize if @wrapper_class.respond_to? :constantize
    #@to = options[:to]

    unless @from # && @to
      raise ArgumentError, 'Not enough arguments. Minimal set of options: :from. Optional arguments: :wrapper_class'
    end
  end

  def run
    wrapper =
        if @wrapper_class
          @wrapper_class
        elsif @from.is_a? BaseUploadHandler
          RedmineConceptualAttachments::StorageWrappers::BaseUploadHandler
        else
          if RedmineConceptualAttachments::StorageWrappers.const_defined? @from.class.name
            RedmineConceptualAttachments::StorageWrappers.const_get(@from.class.name)
          end
        end

    wrapper.new(object: @from) if wrapper
  end
end