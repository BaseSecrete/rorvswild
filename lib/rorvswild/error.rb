# frozen_string_literal: true

module RorVsWild
  class Error
    attr_reader :exception

    def initialize(exception, context = nil)
      @exception = exception
      @execution = RorVsWild.agent.current_execution
      @file, @line = locator.find_most_relevant_file_and_line_from_exception(exception)
      @context = extract_context(context)
      @details = extract_details
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
      }.merge!(@details)
      hash
    end

    def extract_context(given_context)
      hash = defined?(ActiveSupport::ExecutionContext) ? ActiveSupport::ExecutionContext.to_h : {}
      hash.merge!(RorVsWild.agent.error_context) if RorVsWild.agent.error_context
      hash.merge!(@context) if @context
      hash
    end

    def extract_details
      return {} unless data = RorVsWild.agent.current_data
      if controller = data[:controller]
        {
          parameters: controller.request.filtered_parameters,
          request: {
            headers: self.class.extract_http_headers(controller.request.filtered_env),
            name: "#{controller.class}##{controller.action_name}",
            method: controller.request.method,
            url: controller.request.url,
          }
        }
      elsif job = data[:execution]
        {parameters: job.parameters, job: {name: job.name}}
      else
        {}
      end
    end

    def self.extract_http_headers(headers)
      headers.reduce({}) do |hash, (name, value)|
        if name.index("HTTP_") == 0 && name != "HTTP_COOKIE"
          hash[format_header_name(name)] = value
        end
        hash
      end
    end

    HEADER_REGEX = /^HTTP_/.freeze

    def self.format_header_name(name)
      name.sub(HEADER_REGEX, "").split("_").map(&:capitalize).join("-")
    end
  end
end
