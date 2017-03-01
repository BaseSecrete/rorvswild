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
        RorVsWild::Section.start
        commands[event.request_id] = event.command
      end

      def failed(event)
        after_query(event)
      end

      def succeeded(event)
        after_query(event)
      end

      def after_query(event)
        RorVsWild::Section.stop do |section|
          section.kind = "mongo".freeze
          section.command = commands.delete(event.request_id).to_s
        end
      end
    end
  end
end
