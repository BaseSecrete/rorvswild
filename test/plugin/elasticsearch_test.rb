require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "elasticsearch"

class RorVsWild::Plugin::ElasticsearchTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_callback
    skip # TODO: Install Elasticsearch in CI
    agent.measure_block("elastic") do
      ::Elasticsearch::Client.new.search(q: "test")
    end
    assert_equal(1, agent.current_data[:sections].size)
    assert_equal(1, agent.current_data[:sections][0].calls)
    assert_equal("elasticsearch", agent.current_data[:sections][0].kind)
    assert_equal('{"method":"GET","path":"_search","params":{"q":"test"},"body":null}', agent.current_data[:sections][0].command)
  end
end
