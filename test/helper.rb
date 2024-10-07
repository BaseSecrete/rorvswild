# frozen_string_literal: true

GC::Profiler.enable # Enable for Ruby < 3.1

path = File.expand_path("#{File.dirname(__FILE__)}/../lib")
$LOAD_PATH.unshift(path)

require "simplecov"
SimpleCov.start do
  add_filter "test"
end

require "rorvswild"
require "rorvswild/metrics"
require "minitest/autorun"
require "mocha/minitest"
require "minitest/stub_const"
require "top_tests"
require "active_support"

module RorVsWild::AgentHelper
  def agent
    @agent ||= initialize_agent(ignore_requests: ["RorVsWild::Plugin::ActionControllerTest::SecretController#index"])
  end

  def setup
    ActiveSupport::ExecutionContext.clear
  end

  def initialize_agent(options = {})
    agent = RorVsWild.start({logger: "/dev/null", ignore_jobs: ["SecretJob"]}.merge(options))
    agent.locator.stubs(current_path: File.dirname(__FILE__))
    agent.stubs(:send_deployment)
    agent.stubs(:queue_request)
    agent.stubs(:queue_job)
    client = agent.client
    def client.transmit(request)
      # Prevent from any HTTP connections.
      # A stub has no effect, since everythings are unstub before at_exit.
    end
    agent
  end

  def current_sections_without_gc
    agent.current_data[:sections].select { |s| s.kind != "gc" }
  end
end
