path = File.expand_path("#{File.dirname(__FILE__)}/../lib")
$LOAD_PATH.unshift(path)

require "rorvswild"
require "minitest/autorun"
require "mocha/mini_test"
require "top_tests"

module RorVsWildAgentHelper
  def agent
    @agent ||= initialize_agent(app_root: File.dirname(__FILE__))
  end

  def initialize_agent(options = {})
    agent ||= RorVsWild.start({logger: "/dev/null"}.merge(options))
    agent.stubs(:post_request)
    agent.stubs(:post_job)
    agent
  end
end
