# TODO Deep clone previous changes to support nested complex data (from BB)
module Couchbase
  class Model
    module Dirty
      extend ActiveSupport::Concern
      include ActiveModel::Dirty

      included do
        remove_method :write_attribute

        alias_method_chain :save, :dirty
        alias_method_chain :create, :dirty

        attribute_method_prefix :previous_

        class << self
          alias_method_chain :_find, :cleaning
        end
      end

      module ClassMethods
        # If we're just loaded from the database, we're not dirty
        def _find_with_cleaning(quiet, *ids)
          _find_without_cleaning(quiet, *ids).tap do |results|
            Array(results).each {|instance| instance.send :clean! }
          end
        end
      end

      def write_attribute(name, value)
        send "#{name}_will_change!" unless send(name) == value

        @_attributes[name] = value
      end

      def save_with_dirty(options = {})
        save_without_dirty(options).tap do |value|
          capture_previous_changes if value
        end
      end

      def create_with_dirty(options = {})
        create_without_dirty(options).tap do |value|
          capture_previous_changes if value
        end
      end

      # FIXME Return value for "Fail" and "didn't try" is the same
      def save_if_changed(options = {})
        save if changed?
      end

      private
      def capture_previous_changes
        @previously_changed = changes
        @changed_attributes.clear
      end

      def clean!
        @changed_attributes.try(:clear)
        @previously_changed.try(:clear)
      end

      def previous_attribute(attr)
        return unless previous_changes

        previous_changes[attr.to_s].try :first
      end

      def attribute_will_change!(attr)
        begin
          value = __send__(attr)
          value = DeepCopier.new(value).copy
        rescue TypeError, NoMethodError
        end

        changed_attributes[attr] = value
      end

    end
  end
end
