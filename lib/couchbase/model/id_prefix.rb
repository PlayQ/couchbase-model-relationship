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
        @id ||= prefixed_id(Couchbase::Model::UUID.generator.next(1, model.thread_storage[:uuid_algorithm]))

        create_without_id_prefix(options)
      end

      module ClassMethods
        # FIXME Need to handle cases where there's no id, or we fail or 
        # w/e
        def id_prefix
          name.underscore
        end

        def prefixed_id(id)
          "#{id_prefix}:#{unprefixed_id(id)}"
        end

        def unprefixed_id(id)
          id.to_s.split(':').last
        end

        def prefix_from_id(id)
          id.to_s.split(':').first
        end

        def class_from_id(id)
          prefix_from_id(id).classify.constantize
        end
      end
    end
  end
end
