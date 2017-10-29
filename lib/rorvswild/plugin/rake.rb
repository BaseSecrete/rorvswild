module RorVsWild
  module Plugin
    class Rake
      def self.setup
        return if !defined?(::Rake::Application)
        return if ::Rake::Application.method_defined?(:invoke_task_without_rorvswild)
        ::Rake::Application.class_eval do
          alias_method :invoke_task_without_rorvswild, :invoke_task

          def invoke_task(*args)
            RorVsWild.catch_error { invoke_task_without_rorvswild(*args) }
          end
        end
      end
    end
  end
end

RorVsWild::Plugin::Rake.setup # Setup before the first take is invoked.
