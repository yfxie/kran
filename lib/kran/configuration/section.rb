module Kran
  class Configuration
    class Section
      def initialize(raw)
        @section = raw.fetch(name, {}) || {}
      end

      private

      def name
        self.class.name.split("::").last.downcase
      end

      def required(key)
        @section.fetch(key) { raise Error, "Missing #{name}.#{key} in #{Configuration::FILE}" }
      end

      def optional(key, default = nil)
        @section.fetch(key, default)
      end
    end
  end
end
