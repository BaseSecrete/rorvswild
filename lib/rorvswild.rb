require "json/ext"
require "net/http"
require "logger"
require "uri"
require "set"

require "rorvswild/version"
require "rorvswild/location"
require "rorvswild/client"

module RorVsWild
  def self.measure_code(code)
    client ? client.measure_code(code) : eval(code)
  end

  def self.measure_block(name, &block)
    client ? client.measure_block(name , &block) : block.call
  end

  def self.catch_error(extra_details = nil, &block)
    client ? client.catch_error(extra_details, &block) : block.call
  end

  def self.record_error(exception, extra_details = nil)
    client.record_error(exception, extra_details) if client
  end

  def self.register_client(client)
    @client = client
  end

  def self.client
    @client
  end

  module ResquePlugin
    def around_perform_rorvswild(*args, &block)
      RorVsWild.measure_block(to_s, &block)
    end
  end

  class SidekiqPlugin
    def call(worker, item, queue, &block)
      RorVsWild.measure_block(item["wrapped".freeze] || item["class".freeze], &block)
    end
  end
end

if defined?(Rails)
  require "rorvswild/rails_loader"
  RorVsWild::RailsLoader.start_on_rails_initialization
end
