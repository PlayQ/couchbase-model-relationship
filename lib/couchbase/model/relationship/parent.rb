# All this behavior assumes the same bucket/connection options are used for the 
# root object and all children.
#
# TODO Transparent child load if object not present (cache missing objects to reduce queries)
# TODO Support for "required" children (if missing, error) ?
# TODO Use multi-set to batch save parent + children
module Couchbase
  class Model
    module Relationship
      module Parent
        extend ::ActiveSupport::Concern
        
        included do
          alias_method_chain :save, :autosave_children
          alias_method_chain :delete, :autodelete_children
        end

        # TODO How to handle failures saving children?
        def save_with_children(options = {})
          # Don't save if we failed
          save(options).tap do |result|
            children.each do |child|
              child.save_if_changed(options)
            end
          end
        end

        def save_with_autosave_children(options = {})
          # Don't save if we failed
          save_without_autosave_children(options).tap do |result|
            self.class.child_associations.select(&:auto_save).each do |association|
              association.fetch(self).try :save_if_changed, options
            end
          end
        end

        def delete_with_autodelete_children(options = {})
          self.class.child_associations.select(&:auto_delete).each do |association|
            association.fetch(self).try :delete, options
          end

          delete_without_autodelete_children(options)
        end

        # FIXME #changed? should include children if any are autosave

        def delete_with_children(options = {})
          children.each {|child| child.delete options }

          delete(options)
        end

        def children
          self.class.child_associations.map do |association|
            association.fetch self
          end.compact
        end

        module ClassMethods
          def child(name, options = {})
            # TODO This may get the full module path for a relationship name,
            # and that will make the keys very long. Is this necessary? see: AR STI
            name = name.to_s.underscore unless name.is_a?(String)

            (@_children ||= []).push Relationship::Association.new(name, options)

            define_method("#{name}=") do |object|
              # FIXME Sanity check. If parent and parent != self, error
              object.parent = self

              instance_variable_set :"@_child_#{name}", object
            end

            define_method("#{name}") do
              instance_variable_get :"@_child_#{name}"
            end

            define_method("build_#{name}") do |attributes = {}|
              child_class = name.classify.constantize

              send("#{name}=", child_class.new(attributes)).tap do |child|
                child.parent = self
              end
            end
          end

          def children(*names)
            options = names.extract_options!

            names.each {|name| child name, options }
          end

          def child_association_names
            children.map(&:name)
          end

          def child_associations
            @_children ||[]
          end

          def find_with_children(id, *children)
            find_all_with_children(id, *children).first
          end

          def find_all_with_children(ids, *children)
            ids = Array(ids)

            effective_children = if children.blank?
              @_children
            else
              children = children.map(&:to_s)
              @_children.select {|child| children.include?(child.name) }
            end
            
            search_ids = ids.dup
            ids.each do |id|
              search_ids.concat(effective_children.map do |child| 
                child.child_class.prefixed_id(id)
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
