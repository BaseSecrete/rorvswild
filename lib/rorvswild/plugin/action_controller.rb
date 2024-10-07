# frozen_string_literal: true

module RorVsWild
  module Plugin
    class ActionController
      def self.setup
        return if @installed
        return unless defined?(::ActionController::Base)
        ::ActionController::Base.around_action(&method(:around_action))
        ::ActionController::Base.rescue_from(StandardError) { |ex| RorVsWild::Plugin::ActionController.after_exception(ex, self) }

        if defined?(::ActionController::API) && ::ActionController::API.respond_to?(:around_action)
          ::ActionController::API.around_action(&method(:around_action))
          ::ActionController::API.rescue_from(StandardError) { |ex| RorVsWild::Plugin::ActionController.after_exception(ex, self) }
        end
        @installed = true
      end

      def self.around_action(controller, block)
        controller_action = "#{controller.class}##{controller.action_name}"
        return block.call if RorVsWild.agent.ignored_request?(controller_action)
        begin
          RorVsWild::Section.start do |section|
            if method_name = controller.send(:method_for_action, controller.action_name)
              section.file, section.line = controller.method(method_name).source_location
              section.file = RorVsWild.agent.locator.relative_path(section.file)
              section.commands << "#{controller.class}##{method_name}"
            end
            if current_data = RorVsWild.agent.current_data
              current_data[:name] = controller_action
              current_data[:controller] = controller
            end
          end
          block.call
        ensure
          RorVsWild::Section.stop
        end
      end

      def self.after_exception(exception, controller)
        RorVsWild.agent.push_exception(exception)
        raise exception
      end
    end
  end
end
