module RorVsWild
  module Plugin
    class Redis
      def self.setup
        return if !defined?(::Redis)
        return if ::Redis::Client.method_defined?(:process_without_rorvswild)
        ::Redis::Client.class_eval do
          alias_method :process_without_rorvswild, :process

          def process(commands, &block)
            string = commands.map { |command| command.join(" ") }.join("\n")
            RorVsWild.client.measure_query("redis", string) do
              process_without_rorvswild(commands, &block)
            end
          end
        end
      end
    end
  end
end
