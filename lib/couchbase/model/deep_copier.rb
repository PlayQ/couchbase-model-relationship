module Couchbase
  class Model
    class DeepCopier
      attr_reader :source
      def initialize(source)
        @source = source
      end

      def copy
        if cloneable?
          if complex?
            deep_copy
          else
            source.clone
          end
        else
          source
        end
      end

      private
      def cloneable?
        source.duplicable?
      end

      def complex?
        [Array, Hash].include? source.class
      end

      def deep_copy
        shallow = source.clone

        if source.is_a?(Array)
          shallow.clear
          shallow.concat source.map {|value| DeepCopier.new(value).copy }
        elsif source.is_a?(Hash)
          source.each {|key, value| shallow[key] = DeepCopier.new(value).copy }
          shallow
        else
          raise ArgumentError.new("Deep copying a #{source.class} is not supported.")
        end
      end
    end
  end
end
