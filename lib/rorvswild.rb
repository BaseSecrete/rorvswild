require "rorvswild/version"
require "rorvswild/locator"
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
    @logger ||= initialize_logger
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

  def self.initialize_logger(destination = nil)
    if destination.respond_to?(:info) && destination.respond_to?(:warn) && destination.respond_to?(:error)
      destination
    elsif destination
      Logger.new(destination)
    elsif defined?(Rails)
      Rails.logger
    else
      Logger.new(STDOUT)
    end
  end

  def self.clock_milliseconds
    Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
  end

  def self.check
    api_key = RorVsWild.agent.config[:api_key]
    return puts "You API key is missing and has to be defined in config/rorvswild.yml." if !api_key || api_key.empty?
    puts case response = agent.client.post("/jobs", jobs: [{sections: [], name: "RorVsWild.check", runtime: 0}])
    when Net::HTTPOK then "Connection to RorVsWild works fine !"
    when Net::HTTPUnauthorized then "Wrong API key"
    else puts "Something went wrong: #{response.inspect}"
    end
  end
end

if defined?(Rails)
  require "rorvswild/rails_loader"
  RorVsWild::RailsLoader.start_on_rails_initialization
end
