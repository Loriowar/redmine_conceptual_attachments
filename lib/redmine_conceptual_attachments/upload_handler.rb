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
      class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{name}_dirtify_column
          if '#{options[:dirtify_column]}'.present? && self.class.column_names.include?('#{options[:dirtify_column]}')
            '#{options[:dirtify_column]}'
          else
            'id'
          end
        end
      EOT

      if options[:multiple_files].to_bool
        class_eval <<-EOT, __FILE__, __LINE__ + 1
          attr_reader :remove_#{name}, :#{name}_candidates

          after_save :save_#{name}
          before_save :destroy_#{name}
          before_destroy :destroy_all_#{name}

          def #{name}
            #{upload_handler.to_s}.where_container(self).to_a.collect(&:attachment_representation)
          end

          def #{name}=(val)
            @#{name}_candidates = (val.respond_to?(:to_a) ? val.to_a : [val].flatten).compact

            # @note: mark an attribute as dirty for execute callbacks during save
            public_send((#{name}_dirtify_column) + '_will_change!')
          end

          alias #{name}_candidates=  #{name}=

          def save_#{name}
            result = @#{name}_candidates.blank?
            if @#{name}_candidates.present?
              result = transaction do
                @#{name}_candidates.each do |candidate|
                  #{upload_handler}.create(file: candidate, container: self)
                end
              end
            end
            result.present?
          end
          private :save_#{name}

          def remove_#{name}=(val)
            @remove_#{name} =
                (val.respond_to?(:to_a) ? val.to_a : [val].flatten).
                    compact.select{|a| a.is_a? ParametrizedAttachment}

            # @note: mark an attribute as dirty for execute callbacks during save
            public_send((#{name}_dirtify_column) + '_will_change!') if @remove_#{name}.present?
          end

          def destroy_#{name}
            result = @remove_#{name}.blank?
            if @remove_#{name}.present?
              result = transaction do
                #{upload_handler}.where_container(self).
                    where(parametrized_attachment_id: @remove_#{name}.map(&:id)).
                    destroy_all
              end
            end
            result.present?
          end
          private :destroy_#{name}

          def destroy_all_#{name}
            result = #{name}.blank?
            if #{name}.present?
              result = transaction do
                 #{upload_handler}.where_container(self).destroy_all
              end
            end
            result.present?
          end
          private :destroy_all_#{name}
        EOT
      else
        class_eval <<-EOT, __FILE__, __LINE__ + 1
          attr_reader :#{name}_candidate

          after_save :save_#{name}
          before_save :destroy_#{name}_by_mark
          before_destroy :destroy_#{name}

          def #{name}
            #{upload_handler.to_s}.where_container(self).first.try(:attachment_representation)
          end

          def #{name}=(val)
            @#{name}_candidate = val

            # @note: mark an attribute as dirty for execute callbacks during save
            public_send((#{name}_dirtify_column) + '_will_change!')
          end

          alias #{name}_candidate=  #{name}=

          def save_#{name}
            return false unless destroy_#{name}

            result = @#{name}_candidate.blank?
            if @#{name}_candidate.present?
              result = transaction do
                #{upload_handler}.create(file: @#{name}_candidate, container: self)
              end
            end
            result.present?
          end
          private :save_#{name}

          def remove_#{name}
            @remove_#{name} = true

            # @note: mark an attribute as dirty for execute callbacks during save
            public_send((#{name}_dirtify_column) + '_will_change!') if @remove_#{name}.present?
          end

          def destroy_#{name}_by_mark
            result = !@remove_#{name}.to_bool
            if @remove_#{name}.to_bool && #{name}.present?
              result = transaction do
                #{upload_handler}.where_container(self).destroy_all
              end
              @remove_#{name} = false
            end
            result.present?
          end
          private :destroy_#{name}_by_mark

          def destroy_#{name}
            @remove_#{name} = true if #{name}.present?
            destroy_#{name}_by_mark
          end
          private :destroy_#{name}
        EOT
      end
    end
  end
end