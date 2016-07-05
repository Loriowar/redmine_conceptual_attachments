class RedmineConceptualAttachments::Operations::SingleAssignment
  def initialize(options)
    @object = options[:object]

    unless @object
      raise ArgumentError, 'Not enough arguments. Minimal set of options: :object'
    end
  end

  def run
    result =
        if @object.is_a? ActionDispatch::Http::UploadedFile
          @object
        elsif @object.class.name.deconstantize == RedmineConceptualAttachments::StorageWrappers.name
          @object
        else
          RedmineConceptualAttachments::Operations::Copy.new(from: @object).run
        end

    if result.nil?
      raise RuntimeError, "Unable to process object with class #{@object.class.name}"
    else
      result
    end
  end
end