# frozen_string_literal: true

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

      def started(event)
        section = RorVsWild::Section.start
        section.kind = "mongo"
        section.commands << {event.command_name => event.command[event.command_name]}.to_json
      end

      def failed(event)
        after_query(event)
      end

      def succeeded(event)
        after_query(event)
      end

      def after_query(event)
        RorVsWild::Section.stop
      end
    end
  end
end
