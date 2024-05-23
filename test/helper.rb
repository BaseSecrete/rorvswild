# frozen_string_literal: true

path = File.expand_path("#{File.dirname(__FILE__)}/../lib")
$LOAD_PATH.unshift(path)

require "rorvswild"
require "rorvswild/metrics"
require "minitest/autorun"
require "mocha/minitest"
require "top_tests"

module RorVsWild::AgentHelper
  def agent
    @agent ||= initialize_agent(ignore_requests: ["RorVsWild::Plugin::ActionControllerTest::SecretController#index"])
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
