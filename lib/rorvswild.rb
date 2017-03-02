require "rorvswild/version"
require "rorvswild/location"
require "rorvswild/section"

require "rorvswild/plugin/redis"
require "rorvswild/plugin/mongo"
require "rorvswild/plugin/resque"
require "rorvswild/plugin/sidekiq"
require "rorvswild/plugin/net_http"
require "rorvswild/plugin/active_job"
require "rorvswild/plugin/action_view"
require "rorvswild/plugin/active_record"
require "rorvswild/plugin/action_controller"
require "rorvswild/plugin/delayed_job"

require "rorvswild/agent"

module RorVsWild
  def self.start(config)
    @agent = Agent.new(config)
  end

  def self.agent
    @agent
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
end

if defined?(Rails)
  require "rorvswild/rails_loader"
  RorVsWild::RailsLoader.start_on_rails_initialization
end
