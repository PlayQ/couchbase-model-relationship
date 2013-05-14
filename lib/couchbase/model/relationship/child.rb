module Couchbase
  class Model
    module Relationship
      module Child
        extend ::ActiveSupport::Concern

        def create_with_parent_id(options = {})
          if id.blank? && parent.present?
            @id = prefixed_id(parent.id)
          end

          create_without_parent_id(options)
        end

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
