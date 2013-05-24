module Couchbase
  class Model
    module ComplexAttributes
      extend ActiveSupport::Concern

      module ClassMethods
        def array_attribute(*names)
          options = names.extract_options!

          names.each do |name|
            name = name.to_s

            (@_array_attributes ||= {})[name] = options[:class_name]

            define_method("#{name}=") do |values|
              actual_values = values.map do |value|
                if value.is_a?(String) && value =~ /json_class/
                  JSON.load value
                else
                  value
                end
              end

              write_attribute name, actual_values
            end
          end
        end

        def array_attribute_class(name)
          @_array_attributes[name.to_s]
        end
      end
    end
  end
end
