module RorVsWild
  module Plugin
    class Redis
      def self.setup
        return if !defined?(::Redis)
        return if ::Redis::Client.method_defined?(:process_without_rorvswild)
        ::Redis::Client.class_eval do
          alias_method :process_without_rorvswild, :process

          def process(commands, &block)
            string = RorVsWild::Plugin::Redis.commands_to_string(commands)
            appendable = RorVsWild::Plugin::Redis.appendable_commands?(commands)
            RorVsWild.agent.measure_section(string, appendable_command: appendable, kind: "redis".freeze) do
              process_without_rorvswild(commands, &block)
            end
          end
        end
      end

      def self.commands_to_string(commands)
        commands.map { |c| c[0]  }.join("\n".freeze)
      end

      APPENDABLE_COMMANDS = [:auth, :select]

      def self.appendable_commands?(commands)
        commands.size == 1 && APPENDABLE_COMMANDS.include?(commands.first.first)
      end
    end
  end
end
