module Couchbase
  class Model
    module Relationship
      module Parent
        extend ::ActiveSupport::Concern
        
        included do
        end

        module ClassMethods
          def child(name)
            # TODO This may get the full module path for a relationship name,
            # and that will make the keys very long. Is this necessary? see: AR STI
            name = name.to_s.underscore unless name.is_a?(String)

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
          def find_with_children(id, *children)
            find_all_with_children(id, *children).first
          end

          def find_all_with_children(ids, *children)
            ids = Array(ids)

            effective_children = if children.blank?
              @_children
            else
              children.select {|child| @_children.include?(child.to_s) }
            end
            
            search_ids = ids.dup
            ids.each do |id|
              search_ids.concat(effective_children.map do |child| 
                child.classify.constantize.prefixed_id(id)
              end)
            end

            results = bucket.get(search_ids, quiet: true, extended: true)

            parent_objects = ids.map do |id|
              if results.key?(id)
                raw_new(id, results.delete(id))
              else
                raise Couchbase::Error::NotFound.new("failed to get value (key=\"#{id}\"")
              end
            end

            parent_objects.each do |parent|
              results.each do |child_id, child_attributes|
                if unprefixed_id(parent.id) == unprefixed_id(child_id) 
                  parent.send "#{prefix_from_id child_id}=", 
                    class_from_id(child_id).raw_new(child_id, child_attributes)
                end
              end
            end
          end

          def raw_new(id, results)
            obj, flags, cas = results
            obj = {:raw => obj} unless obj.is_a?(Hash)
            new({:id => id, :meta => {'flags' => flags, 'cas' => cas}}.merge(obj))
          end
        end
      end
    end
  end
end
