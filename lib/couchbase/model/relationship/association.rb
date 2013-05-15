module Couchbase
  class Model
    module Relationship
      class Association
        attr_accessor :name
        attr_reader :auto_save

        def initialize(name, options = {})
          self.name = name.to_s
          @auto_save = options[:auto_save]
        end

        def fetch(parent)
          parent.send(name)
        end

        def child_klass
          name.classify
        end

        def child_class
          child_klass.constantize
        end
      end
    end
  end
end
