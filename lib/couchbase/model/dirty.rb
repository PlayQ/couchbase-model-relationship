module Couchbase
  class Model
    module Dirty
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Dirty

        remove_method :write_attribute

        alias_method_chain :save, :dirty
        alias_method_chain :create, :dirty
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

      private
      def capture_previous_changes
        @previously_changed = changes
        @changed_attributes.clear
      end

      def clean!
        @changed_attributes.clear
      end


    end
  end
end
