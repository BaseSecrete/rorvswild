require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "mongo"

class RorVsWild::Plugin::MongoTest < Minitest::Test
  include RorVsWildAgentHelper

  Mongo::Logger.logger.level = ::Logger::FATAL

  def test_callback
    mountains = [
      {name: "Mont Blanc", altitude: 4807},
      {name: "Mont Cervin", altitude: 4478},
    ]
    agent.measure_block("mongo") do
      agent = Mongo::Client.new('mongodb://127.0.0.1:27017/test')
      mountains.each { |m| agent[:mountains].insert_one(m) }
    end
    assert_equal(1, agent.send(:sections).size)
    assert_equal(2, agent.send(:sections)[0].calls)
    assert_equal("mongo", agent.send(:sections)[0].kind)
    assert_match('{"insert"=>"mountains", "documents"=>', agent.send(:sections)[0].command)
  end
end
