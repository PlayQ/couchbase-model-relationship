module Couchbase
  class Model
    module Relationship
      module Parent
        extend ::ActiveSupport::Concern
        
        included do
        end

        module ClassMethods
          def child(name)
            (@_children ||= []).push name

            define_method("#{name}=") do |object|
              instance_variable_set :"@_child_#{name}", object
            end

            define_method("#{name}") do
              instance_variable_get :"@_child_#{name}"
            end
          end

          def children(*names)
            names.each {|name| child name }
          end

          # FIXME Need to support finding multiple instances with their own children
          # Without doing [id]x queries
          def find_with_children(id, children = [])
            children = children.blank? ? @_children : children

            child_ids = children.map {|child| child.classify.constantize.prefixed_id(id) }

            results = bucket.get([id, *child_ids], quiet: true, extended: true)

            #FIXME The data might be a string here, whereas with a single get it's a hash. Check
            parent_attributes = results.delete(id)

            if parent_attributes.nil?
              # raise CB not found error
            end

            parent = raw_new(parent_attributes)

            results.each do |child_id, child_attributes|
              parent.send("#{prefix_from_id child_id}=", class_from_id(child_id).raw_new(child_attributes))
            end
              
          end

          def raw_new(results)
            obj, flags, cas = results
            obj = {:raw => obj} unless obj.is_a?(Hash)
            new({:id => id, :meta => {'flags' => flags, 'cas' => cas}}.merge(obj))
          end
        end
      end
    end
  end
end
