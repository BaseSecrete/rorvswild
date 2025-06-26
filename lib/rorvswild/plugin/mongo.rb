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
        section.commands << normalize_query(event.command).to_json
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

      QUERY_ROOT_KEYS = %w[
        insert update delete findAndModify bulkWrite
        find aggregate count distinct
        create drop listCollections listDatabases dropDatabase
        startSession commitTransaction abortTransaction
        filter getMore collection sort
      ]

      def normalize_query(query)
        query = query.slice(*QUERY_ROOT_KEYS)
        query["filter"] = normalize_hash(query["filter"]) if query["filter"]
        query["getMore"] = normalize_value(query["getMore"]) if query["getMore"]
        query
      end

      def normalize_hash(hash)
        (hash = hash.to_h).each { |key, val| hash[key] = normalize_value(val) }
      end

      def normalize_array(array)
        array.map { |value| normalize_value(value) }
      end

      def normalize_value(value)
        case value
        when Hash then normalize_hash(value.to_h)
        when Array then normalize_array(value)
        when FalseClass then false
        when TrueClass then true
        when NilClass then nil
        else "?"
        end
      end
    end
  end
end
