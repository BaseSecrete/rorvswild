require "rorvswild/version"
require "rorvswild/location"
require "rorvswild/plugin/redis"
require "rorvswild/plugin/mongo"
require "rorvswild/plugin/resque"
require "rorvswild/plugin/sidekiq"
require "rorvswild/plugin/net_http"
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
end

if defined?(Rails)
  require "rorvswild/rails_loader"
  RorVsWild::RailsLoader.start_on_rails_initialization
end
