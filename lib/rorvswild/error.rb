# frozen_string_literal: true

module RorVsWild
  class Error
    attr_reader :exception

    attr_accessor :details

    def initialize(exception, context = nil)
      @exception = exception
      @file, @line = locator.find_most_relevant_file_and_line_from_exception(exception)
      @context = extract_context(context)
    end

    def locator
      RorVsWild.agent.locator
    end

    def as_json(options = nil)
      hash = {
        line: @line.to_i,
        file: locator.relative_path(@file),
        message: exception.message[0,1_000_000],
        backtrace: exception.backtrace || ["No backtrace"],
        exception: exception.class.to_s,
        context: @context,
        environment: Host.to_h,
      }
      hash.merge!(details) if details
      hash
    end

    def extract_context(given_context)
      hash = defined?(ActiveSupport::ExecutionContext) ? ActiveSupport::ExecutionContext.to_h : {}
      hash.merge!(RorVsWild.agent&.current_execution&.error_context || {})
      hash.merge!(given_context) if given_context.is_a?(Hash)
      hash
    end
  end
end
