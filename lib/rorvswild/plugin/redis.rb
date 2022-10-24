module RorVsWild
  module Plugin
    class Redis
      def self.setup
        return if !defined?(::Redis)
        if ::Redis::Client.method_defined?(:process)
          ::Redis::Client.prepend(V4)
        else
          ::Redis.prepend(V5)
        end
      end

      module V4
        def process(commands, &block)
          string = RorVsWild::Plugin::Redis.commands_to_string(commands)
          appendable = RorVsWild::Plugin::Redis.appendable_commands?(commands)
          RorVsWild.agent.measure_section(string, appendable_command: appendable, kind: "redis".freeze) do
            super(commands, &block)
          end
        end
      end

      module V5
        def send_command(command, &block)
          appendable = RorVsWild::Plugin::Redis.appendable_commands?(command)
          RorVsWild.agent.measure_section(command[0], appendable_command: appendable, kind: "redis".freeze) do
            super(command, &block)
          end
        end

        # TODO: Monitor pipelined
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
