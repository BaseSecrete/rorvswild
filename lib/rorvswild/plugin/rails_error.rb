# frozen_string_literal: true

module RorVsWild
  module Plugin
    class RailsError
      def self.setup
        return if @installed
        return if !defined?(Rails.error)
        return if !defined?(ActiveSupport::ErrorReporter)
        Rails.error.subscribe(new)
        @installed = true
      end

      def report(error, handled:, severity:, context:, source:)
        RorVsWild.record_error(error, context)
      end
    end
  end
end
