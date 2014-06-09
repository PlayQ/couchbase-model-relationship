module Couchbase
  class Model
    module Relationship
      module Child

        extend ::ActiveSupport::Concern

        def create_with_parent_id(options = {})
          if id.blank? && parent.present?
            @id = prefixed_id(parent.id)
          end

          # Should this only fire if we had a parent and assigned the id?
          begin
            create_without_parent_id(options)
          rescue Couchbase::Error::KeyExists => error
            if ok_to_merge_on_key_exists_error?
              on_key_exists_merge_from_db!

              save # Can't retry because that still tries 'add'
            else
              raise error
            end
          end
        end

        def ok_to_merge_on_key_exists_error?
          respond_to?(:on_key_exists_merge_from_db!) &&
            parent.present? &&
            id == prefixed_id(parent.id)
        end
        private :ok_to_merge_on_key_exists_error?

        module ClassMethods
          def has_parent
            attr_accessor :parent

            alias_method_chain :create, :parent_id
          end
        end
      end
    end
  end
end
