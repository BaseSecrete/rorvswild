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

    sections = current_user_sections
    assert_equal(3, sections.size)

    assert_equal(1, sections[0].calls)
    assert_equal("mongo", sections[0].kind)
    assert_equal({drop: "mountains"}.to_json, sections[0].command)

    assert_equal(2, sections[1].calls)
    assert_equal("mongo", sections[1].kind)
    assert_equal({insert: "mountains"}.to_json, sections[1].command)

    assert_equal(1, sections[2].calls)
    assert_equal("mongo", sections[2].kind)
    assert_equal({find: "mountains", filter: {altitude: {"$gt": "?"} }}.to_json, sections[2].command)
  end

  def test_normalize_query
    plugin = RorVsWild::Plugin::Mongo.new

    query = {"find" => "collection", "filter" => {"some_id" => 123, "date": {"$gt": "2015-06-06"}}, "$db" => "db", "lsid"=>{"id"=>123}}
    assert_equal({"find" => "collection", "filter" => {"some_id" => "?", "date": {"$gt": "?"}}}, plugin.normalize_query(query))

    query = {"getMore" => 123, "collection" => "collection", "$db": "db", "lsid": {id: 123}}
    assert_equal({"getMore" => "?", "collection" => "collection"}, plugin.normalize_query(query))

    query = {
      "find" => "collection",
      "filter" => {
        "id" => 123,
        "bool" => {"$ne" => true},
        "$or" => [{"date" => {"$gt" => "2015-06-06"}}, {"date" => nil}]
      },
      "projection" => {col1: 0, col2: 0},
      "sort" => {"date" => 1},
      "$db" => "db",
      "lsid" => {"id" => 123}
    }
    assert_equal(
      {
        "find" => "collection",
        "filter" => {
          "id" => "?",
          "bool" => {"$ne" => true},
          "$or" => [{"date" => {"$gt" => "?"}}, {"date" => nil}]
        },
        "sort" => {"date" => 1},
      },
      plugin.normalize_query(query)
    )
  end
end
