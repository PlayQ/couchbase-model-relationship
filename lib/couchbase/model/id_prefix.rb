module Couchbase
  class Model
    module IdPrefix
      extend ::ActiveSupport::Concern

      included do
        alias_method_chain :create, :id_prefix
      end

      def prefixed_id(id)
        self.class.prefixed_id(id)
      end

      def create_with_id_prefix(options = {})
        ensure_has_id
        create_without_id_prefix(options)
      end

      def ensure_has_id
        @id ||= model.next_prefixed_id
      end
      private :ensure_has_id

      module ClassMethods
        # FIXME Need to handle cases where there's no id, or we fail or 
        # w/e
        def id_prefix
          name.underscore
        end

        def next_prefixed_id
          prefixed_id(next_unprefixed_id)
        end

        def next_unprefixed_id
          Couchbase::Model::UUID.generator.next(1, thread_storage[:uuid_algorithm])
        end

        def prefixed_id(id)
          "#{id_prefix}:#{unprefixed_id(id)}"
        end

        def unprefixed_id(id)
          id_parts(id).last
        end

        def prefix_from_id(id)
          id_parts(id).first
        end

        def class_from_id(id)
          prefix_from_id(id).classify.constantize
        end

        def id_parts(id)
          id.to_s.split(':')
        end
      end
    end
  end
end
