module RorVsWild
  module Plugin
    class Mongo
      def self.setup
        ::Mongo::Monitoring::Global.subscribe(::Mongo::Monitoring::COMMAND, Mongo.new)
      end

      attr_reader :commands

      def initialize
        @commands = {}
      end

      def started(event)
        commands[event.request_id] = event.command
      end

      def failed(event)
        after(event)
      end

      def succeeded(event)
        after(event)
      end

      def after(event)
        runtime = event.duration * 1000
        command = commands.delete(event.request_id).to_s
        file, line, method = RorVsWild.client.extract_most_relevant_location(caller)
        RorVsWild.client.send(:push_query, kind: "mongo", command: command, file: file, line: line, method: method, runtime: runtime)
      end
    end
  end
end
