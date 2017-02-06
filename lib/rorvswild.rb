require "json/ext"
require "net/http"
require "logger"
require "uri"
require "set"

require "rorvswild/version"
require "rorvswild/location"
require "rorvswild/client"

module RorVsWild
  def self.new(*args)
    warn "WARNING: RorVsWild.new is deprecated. Use RorVsWild::Client.new instead."
    Client.new(*args) # Compatibility with 0.0.1
  end

  def self.detect_config_file
    return if !defined?(Rails)
    Rails::Railtie.initializer "rorvswild.detect_config_file" do
      if !RorVsWild.default_client && (path = Rails.root.join("config/rorvswild.yml")).exist?
        if config = RorVsWild.load_config_file(path)[Rails.env]
          RorVsWild::Client.new(config.symbolize_keys)
        end
      end
    end
  end

  def self.load_config_file(path)
    YAML.load(ERB.new(path.read).result)
  end

  def self.register_default_client(client)
    @default_client = client
  end

  def self.default_client
    @default_client
  end

  def self.measure_job(code)
    default_client ? default_client.measure_job(code) : eval(code)
  end

  def self.measure_code(code)
    default_client ? default_client.measure_code(code) : eval(code)
  end

  def self.measure_block(name, &block)
    default_client ? default_client.measure_block(name , &block) : block.call
  end

  def self.catch_error(extra_details = nil, &block)
    default_client ? default_client.catch_error(extra_details, &block) : block.call
  end

  def self.record_error(exception, extra_details = nil)
    default_client.record_error(exception, extra_details) if default_client
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

RorVsWild.detect_config_file
