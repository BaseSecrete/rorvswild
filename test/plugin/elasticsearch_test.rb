require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "elasticsearch"

class RorVsWild::Plugin::ElasticsearchTest < Minitest::Test
  include RorVsWildAgentHelper

  def test_callback
    agent.measure_block("elastic") do
      ::Elasticsearch::Client.new.search(q: "test")
    end
    assert_equal(2, agent.data[:sections].size) # TODO: Ignore HTTP
    assert_equal(1, agent.data[:sections][1].calls)
    assert_equal("elasticsearch", agent.data[:sections][1].kind)
    assert_equal('{"method":"GET","path":"_search","params":{"q":"test"},"body":null}', agent.data[:sections][1].command)
  end
end
