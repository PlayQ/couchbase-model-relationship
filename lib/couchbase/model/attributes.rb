module Couchbase
  class Model
    module Attributes
      extend ::ActiveSupport::Concern

      included do
        include ::ActiveModel::AttributeMethods

        class << self
          remove_method :attribute
        end
      end

      module ClassMethods
        def attribute(*names)
          options = {}
          if names.last.is_a?(Hash)
            options = names.pop
          end

          names.each do |name|
            name = name.to_s
            attributes[name] = options[:default]

            define_attribute_methods([name])

            define_method(name) do
              read_attribute name
            end

            define_method("#{name}=") do |value|
              write_attribute name, value
            end
          end
        end
      end
    end
  end
end
