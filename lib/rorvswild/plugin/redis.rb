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
          string = commands.map(&:first).join("\n")
          appendable = APPENDABLE_COMMANDS.include?(commands[0][0])
          RorVsWild.agent.measure_section(string, appendable_command: appendable, kind: "redis".freeze) do
            super(commands, &block)
          end
        end
      end

      module V5
        def send_command(command, &block)
          appendable = APPENDABLE_COMMANDS.include?(command)
          RorVsWild.agent.measure_section(command[0], appendable_command: appendable, kind: "redis".freeze) do
            super(command, &block)
          end
        end

        def pipelined
          RorVsWild.agent.measure_section("pipeline", kind: "redis".freeze) do
            super
          end
        end

        def multi
          RorVsWild.agent.measure_section("multi", kind: "redis".freeze) do
            super
          end
        end
      end

      APPENDABLE_COMMANDS = [:auth, :select]
    end
  end
end
