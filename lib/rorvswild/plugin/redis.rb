module RorVsWild
  module Plugin
    class Redis
      def self.setup
        return if !defined?(::Redis)
        ::Redis::Client.class_eval do
          alias_method :process_without_rorvswild, :process

          def process(commands, &block)
            RorVsWild.default_client.measure_query("redis", commands) do
              process_without_rorvswild(commands, &block)
            end
          end
        end
      end
    end
  end
end
