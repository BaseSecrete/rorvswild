module RorVsWild
  module Plugin
    class ActionController
      def self.setup
        return if @installed
        return unless defined?(::ActionController::Base)
        ActiveSupport::Notifications.subscribe("process_action.action_controller", new)
        ::ActionController::Base.around_action(&method(:around_action))
        ::ActionController::Base.rescue_from(StandardError) { |ex| RorVsWild::Plugin::ActionController.after_exception(ex, self) }
        @installed = true
      end

      def self.after_exception(exception, controller)
        if hash = RorVsWild.agent.push_exception(exception)
          hash[:session] = controller.session.to_hash
          hash[:parameters] = controller.request.filtered_parameters
          hash[:environment_variables] = extract_http_headers(controller.request.filtered_env)
        end
        raise exception
      end

      def self.around_action(controller, block)
        begin
          RorVsWild::Section.start do |section|
            method_name = controller.method_for_action(controller.action_name)
            section.file, section.line = controller.method(method_name).source_location
            section.command = "#{controller.class}##{method_name}"
            section.kind = "code".freeze
          end
          block.call
        ensure
          RorVsWild::Section.stop
        end
      end

      # Payload: controller, action, params, format, method, path
      def start(name, id, payload)
        name = "#{payload[:controller]}##{payload[:action]}"
        RorVsWild.agent.start_request(name: name, path: payload[:path])
      end

      def finish(name, id, payload)
        RorVsWild.agent.stop_request
      end

      def self.extract_http_headers(headers)
        headers.reduce({}) do |hash, (name, value)|
          if name.index("HTTP_".freeze) == 0 && name != "HTTP_COOKIE".freeze
            hash[format_header_name(name)] = value
          end
          hash
        end
      end

      HEADER_REGEX = /^HTTP_/.freeze

      def self.format_header_name(name)
        name.sub(HEADER_REGEX, ''.freeze).split("_".freeze).map(&:capitalize).join("-".freeze)
      end
    end
  end
end
