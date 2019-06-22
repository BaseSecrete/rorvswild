path = File.expand_path("#{File.dirname(__FILE__)}/../lib")
$LOAD_PATH.unshift(path)

require "rorvswild"
require "minitest/autorun"
require "mocha/mini_test"
require "top_tests"

module RorVsWild::AgentHelper
  def agent
    @agent ||= initialize_agent(app_root: File.dirname(__FILE__), ignore_requests: ["SecretController#index"])
  end

  def initialize_agent(options = {})
    agent ||= RorVsWild.start({logger: "/dev/null", ignore_jobs: ["SecretJob"]}.merge(options))
    agent.stubs(:post_request)
    agent.stubs(:post_job)
    agent
  end
end
