require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "mongo"

class RorVsWild::Plugin::MongoTest < Minitest::Test
  include RorVsWild::AgentHelper

  Mongo::Logger.logger.level = ::Logger::FATAL

  def test_callback
    mountains = [
      {name: "Mont Blanc", altitude: 4807},
      {name: "Mont Cervin", altitude: 4478},
    ]
    agent.locator.stubs(current_path: File.dirname(__FILE__))

    agent.measure_block("mongo") do
      mongo = Mongo::Client.new("mongodb://127.0.0.1:27017/test")
      mongo[:mountains].drop()
      mountains.each { |m| mongo[:mountains].insert_one(m) }
      mongo[:mountains].find(altitude: {"$gt": 4800}).each { |mountain| }
    end

    sections = agent.current_data[:sections]
    assert_equal(3, sections.size)

    assert_equal(1, sections[0].calls)
    assert_equal("mongo", sections[0].kind)
    assert_match({drop: "mountains"}.to_json, sections[0].command)

    assert_equal(2, sections[1].calls)
    assert_equal("mongo", sections[1].kind)
    assert_match({insert: "mountains"}.to_json, sections[1].command)

    assert_equal(1, sections[2].calls)
    assert_equal("mongo", sections[2].kind)
    assert_match({find: "mountains"}.to_json, sections[2].command)
  end
end
