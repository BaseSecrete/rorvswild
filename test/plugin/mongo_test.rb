require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "mongo"

class RorVsWild::Plugin::MongoTest < Minitest::Test
  Mongo::Logger.logger.level = ::Logger::FATAL

  def test_callback
    mountains = [
      {name: "Mont Blanc", altitude: 4807},
      {name: "Mont Cervin", altitude: 4478},
    ]
    client.measure_block("mongo") do
      client = Mongo::Client.new('mongodb://127.0.0.1:27017/test')
      mountains.each { |m| client[:mountains].insert_one(m) }
    end
    assert_equal(1, client.send(:sections).size)
    assert_equal(2, client.send(:sections)[0].calls)
    assert_equal("mongo", client.send(:sections)[0].kind)
    assert_match('{"insert"=>"mountains", "documents"=>', client.send(:sections)[0].command)
  end

  private

  def client
    @client ||= initialize_client(app_root: "/rails/root")
  end

  def initialize_client(options = {})
    client = RorVsWild::Client.new(options)
    client.stubs(:post_request)
    client.stubs(:post_job)
    client
  end
end
