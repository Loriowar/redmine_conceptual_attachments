module RedmineConceptualAttachments::UploadHandler
  extend ActiveSupport::Concern

  included do
    # stub
  end

  #instance methods were here

  module ClassMethods
    # @todo: need to add an option for specify relation type: one or many
    def upload_handler(name, upload_handler, options = {})

      # common methods
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}_dirtify_column
          if '#{options[:dirtify_column]}'.present? && self.class.column_names.include?('#{options[:dirtify_column]}')
            '#{options[:dirtify_column]}'
          else
            'id'
          end
        end

        # @todo: replace all below interpolations of upload_handler to using of this method
        def #{name}_upload_handler
          #{upload_handler.to_s}
        end

        def #{name}_multiple_files?
          #{options[:multiple_files].to_bool}
        end

        def #{name}_single_file?
          !#{name}_multiple_files?
        end
      RUBY

      if options[:multiple_files].to_bool
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          attr_reader :remove_#{name}, :#{name}_candidates

          before_validation :upload_handler_fill_new_#{name}
          validate :upload_handler_validate_#{name}

          after_save     :upload_handler_save_#{name}
          # may occur problem in case of multiple save of single AR instance with attached file through upload_handler
          after_commit   :upload_handler_clear_context_for_#{name}
          before_save    :upload_handler_destroy_#{name}
          before_destroy :upload_handler_destroy_all_#{name}

          def #{name}
            #{upload_handler.to_s}.where_container(self).to_a.collect(&:attachment_representation)
          end

          def #{name}=(val)
            @#{name}_candidates = (val.respond_to?(:to_a) ? val.to_a : [val].flatten).compact

            # @note: mark an attribute as dirty for execute callbacks during save
            public_send((#{name}_dirtify_column) + '_will_change!')
          end

          alias #{name}_candidates= #{name}=

          def upload_handler_save_#{name}
            result = @#{name}_candidates.blank?
            if @#{name}_candidates.present?
              result = transaction do
                @#{name}_new_objects.each do |candidate|
                  candidate.save
                end
              end
            end
            result.present?
          end
          private :upload_handler_save_#{name}

          def upload_handler_clear_context_for_#{name}
            @#{name}_candidates = nil
            @#{name}_new_objects = nil
          end
          private :upload_handler_clear_context_for_#{name}

          def remove_#{name}=(val)
            @remove_#{name} =
                (val.respond_to?(:to_a) ? val.to_a : [val].flatten).
                    compact.select{|a| a.is_a? ParametrizedAttachment}

            # @note: mark an attribute as dirty for execute callbacks during save
            public_send((#{name}_dirtify_column) + '_will_change!') if @remove_#{name}.present?
          end

          def upload_handler_destroy_#{name}
            result = @remove_#{name}.blank?
            if @remove_#{name}.present?
              result = transaction do
                @remove_#{name}.each do |attachment|
                  #{upload_handler}.where_container(self).
                      where(filename: attachment.filename,
                            parametrized_attachment_id: attachment.id).destroy_all
                end
              end
            end
            result.present?
          end
          private :upload_handler_destroy_#{name}

          def upload_handler_destroy_all_#{name}
            result = #{name}.blank?
            if #{name}.present?
              result = transaction do
                 #{upload_handler}.where_container(self).destroy_all
              end
            end
            result.present?
          end
          private :upload_handler_destroy_all_#{name}

          def upload_handler_fill_new_#{name}
            if @#{name}_candidates.present?
              # @todo: somewhere here must be a rejection of duplicates (by filename and digest)
              @#{name}_new_objects =
                  @#{name}_candidates.collect do |candidate|
                    #{upload_handler}.new(file: candidate,
                                          container: self,
                                          container_type: self.class.name,
                                          available_extensions: #{options[:extensions].to_a},
                                          available_content_types: #{options[:content_types].to_a})
                  end
            end
          end
          private :upload_handler_fill_new_#{name}

          def upload_handler_validate_#{name}
            unless @#{name}_new_objects.blank? || @#{name}_new_objects.all?(&:valid?)
              @#{name}_new_objects.map{|o| o.errors.full_messages}.flatten.uniq.each{|e| errors.add(:base, e)}
            end
          end
          private :upload_handler_validate_#{name}
        RUBY
      else
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          attr_reader :#{name}_candidate

          before_validation :upload_handler_fill_new_#{name}
          validate :upload_handler_validate_#{name}

          after_save     :upload_handler_save_#{name}
          # may occur problem in case of multiple save of single AR instance with attached file through upload_handler
          after_commit   :upload_handler_clear_context_for_#{name}
          before_save    :upload_handler_destroy_#{name}_by_mark
          before_destroy :upload_handler_destroy_#{name}

          def #{name}
            #{upload_handler.to_s}.where_container(self).first.try(:attachment_representation)
          end

          def #{name}=(val)
            unless val.nil?
              @#{name}_candidate =
                  ::RedmineConceptualAttachments::Operations::SingleAssignment.new(object: val).run

              # @note: mark an attribute as dirty for execute callbacks during save
              public_send((#{name}_dirtify_column) + '_will_change!')
            end
          end

          alias #{name}_candidate= #{name}=

          # options must contain follows keys: :source and :name
          def copy_#{name}_from_upload_handler(options)
            source_upload_handler_class = options[:source].public_send(options[:name].to_s + '_upload_handler')
            source_upload_handler = source_upload_handler_class.where_container(options[:source]).first
            if source_upload_handler.present? && options[:source].public_send(options[:name].to_s + '_single_file?')
              public_send(:#{name}=,
                          #{upload_handler}.copy_operation.new(from: source_upload_handler).run)
              true
            else
              false
            end
          end

          # options must contain follows keys: :object (obligated) and :wrapper_class (optional, can be obtain automatically)
          def copy_#{name}_from_external(options)
            public_send(:#{name}=,
                        #{upload_handler}.copy_operation.new(from: options[:object],
                                                             wrapper_class: options[:wrapper_class]).run)
            true
          end

          def upload_handler_save_#{name}
            result = @#{name}_new_object.blank?
            if @#{name}_new_object.present?
              result = transaction do
                upload_handler_destroy_#{name}
                @#{name}_new_object.save
              end
            end
            result.present?
          end
          private :upload_handler_save_#{name}

          def upload_handler_clear_context_for_#{name}
            @#{name}_candidate = nil
            @#{name}_new_object = nil
          end
          private :upload_handler_clear_context_for_#{name}

          def remove_#{name}
            @remove_#{name} = true

            # @note: mark an attribute as dirty for execute callbacks during save
            public_send((#{name}_dirtify_column) + '_will_change!') if @remove_#{name}.present?
          end

          def upload_handler_destroy_#{name}_by_mark
            result = !@remove_#{name}.to_bool
            if @remove_#{name}.to_bool && #{name}.present?
              result = transaction do
                #{upload_handler}.where_container(self).destroy_all
              end
              @remove_#{name} = false
            end
            result.present?
          end
          private :upload_handler_destroy_#{name}_by_mark

          def upload_handler_destroy_#{name}
            @remove_#{name} = true if #{name}.present?
            upload_handler_destroy_#{name}_by_mark
          end
          private :upload_handler_destroy_#{name}

          def upload_handler_fill_new_#{name}
            if @#{name}_candidate.present?
              @#{name}_new_object =
                  #{upload_handler}.new(file: @#{name}_candidate,
                                        container: self,
                                        container_type: self.class.name,
                                        available_extensions: #{options[:extensions].to_a},
                                        available_content_types: #{options[:content_types].to_a})
            end
          end
          private :upload_handler_fill_new_#{name}

          def upload_handler_validate_#{name}
            unless @#{name}_new_object.blank? || @#{name}_new_object.valid?
              @#{name}_new_object.errors.full_messages.each{|e| errors.add(:base, e)}
            end
          end
          private :upload_handler_validate_#{name}
        RUBY
      end
    end
  end
end
