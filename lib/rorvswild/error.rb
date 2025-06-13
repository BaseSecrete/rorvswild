# frozen_string_literal: true

module RorVsWild
  class Error
    attr_reader :exception

    def initialize(exception, context = nil)
      @exception = exception
      @file, @line = locator.find_most_relevant_file_and_line_from_exception(exception)
      @context = context
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
        context: merged_context,
        environment: Host.to_h,
      }
      details = controller_details and hash.merge!(details)
      hash
    end

    def merged_context
      hash = defined?(ActiveSupport::ExecutionContext) ? ActiveSupport::ExecutionContext.to_h : {}
      hash.merge!(RorVsWild.agent.error_context) if RorVsWild.agent.error_context
      hash.merge!(@context) if @context
      hash
    end

    def controller_details
      if controller = RorVsWild.agent.current_data && RorVsWild.agent.current_data[:controller]
        {
          parameters: controller.request.filtered_parameters,
          request: {
            headers: self.class.extract_http_headers(controller.request.filtered_env),
            name: "#{controller.class}##{controller.action_name}",
            method: controller.request.method,
            url: controller.request.url,
          }
        }
      end
    end

    def self.extract_http_headers(headers)
      headers.reduce({}) do |hash, (name, value)|
        if name.start_with?("HTTP_") && name != "HTTP_COOKIE"
          hash[format_header_name(name)] = value
        end
        hash
      end
    end

    def self.format_header_name(name)
      name.delete_prefix("HTTP_").split("_").each(&:capitalize!).join("-")
    end
  end
end
