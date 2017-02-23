module RorVsWild
  module Plugin
    class Mongo
      def self.setup
        return if @installed
        return if !defined?(::Mongo::Monitoring::Global)
        ::Mongo::Monitoring::Global.subscribe(::Mongo::Monitoring::COMMAND, Mongo.new)
        @installed = true
      end

      attr_reader :commands

      def initialize
        @commands = {}
      end

      def started(event)
        commands[event.request_id] = event.command
      end

      def failed(event)
        after_query(event)
      end

      def succeeded(event)
        after_query(event)
      end

      def after_query(event)
        runtime = event.duration * 1000
        command = commands.delete(event.request_id).to_s
        file, line, method = RorVsWild.client.extract_most_relevant_location(caller)
        RorVsWild.client.send(:push_query, kind: "mongo", command: command, file: file, line: line, method: method, runtime: runtime)
      end
    end
  end
end
