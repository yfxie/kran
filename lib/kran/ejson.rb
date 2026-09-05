require "json"
require "kran/shell"

module Kran
  class Ejson
    attr_reader :path

    def initialize(path, runner: Kran.runner)
      @path = path
      @runner = runner
    end

    def fetch(dotted_path)
      value = document.dig(*dotted_path.split("."))
      raise Error, "#{dotted_path} not found in #{path}" if value.nil?

      value
    end

    private

    def document
      Dependencies.new(runner: @runner).ensure!("ejson")
      @document ||= JSON.parse(@runner.capture("ejson decrypt #{Shell.escape(path)}"))
    end
  end
end
