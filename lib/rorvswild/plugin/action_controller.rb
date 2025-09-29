# frozen_string_literal: true

module RorVsWild
  module Plugin
    class ActionController
      @installed = false

      def self.setup(agent)
        return if @installed
        return unless defined?(::ActionController::Base)
        ::ActionController::Base.around_action(&method(:around_action))
        if defined?(::ActionController::API) && ::ActionController::API.respond_to?(:around_action)
          ::ActionController::API.around_action(&method(:around_action))
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
            if execution = RorVsWild.agent.current_execution
              execution.name = controller_action
              execution.controller = controller
            end
          end
          block.call
        rescue => exception
          RorVsWild.agent.current_execution&.add_exception(exception)
          raise
        ensure
          RorVsWild::Section.stop
        end
      end
    end
  end
end
