require "rorvswild/version"
require "rorvswild/location"
require "rorvswild/section"
require "rorvswild/client"
require "rorvswild/plugins"
require "rorvswild/queue"
require "rorvswild/agent"

module RorVsWild
  def self.start(config)
    @logger = initialize_logger(config[:logger])
    @agent = Agent.new(config)
  rescue Exception => ex
    logger.error(ex)
    raise
  end

  def self.agent
    @agent
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.measure_code(code)
    agent ? agent.measure_code(code) : eval(code)
  end

  def self.measure_block(name, &block)
    agent ? agent.measure_block(name , &block) : block.call
  end

  def self.catch_error(extra_details = nil, &block)
    agent ? agent.catch_error(extra_details, &block) : block.call
  end

  def self.record_error(exception, extra_details = nil)
    agent.record_error(exception, extra_details) if agent
  end

  def self.initialize_logger(destination)
    if destination
      Logger.new(destination)
    elsif defined?(Rails)
      Logger.new(Rails.root + "log/rorvswild.log")
    end
  end
end

if defined?(Rails)
  require "rorvswild/rails_loader"
  RorVsWild::RailsLoader.start_on_rails_initialization
end
