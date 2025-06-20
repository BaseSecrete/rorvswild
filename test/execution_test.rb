require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::ExecutionTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_format_header_name
    agent
    request = RorVsWild::Execution::Request.new("/")
    request.expects(controller: stub(request: stub(filtered_env: {"HTTP_CONTENT_TYPE" => "HTML", "HTTP_COOKIE" => "data", "HTTP_X_QUEUE_START" => "1234", "foo.bar" => "baz"})))
    assert_equal({"Content-Type" => "HTML", "X-Queue-Start" => "1234"}, request.headers)
  end

  def test_add_queue_time
    agent
    execution = RorVsWild::Execution.new("name", nil)
    old_started_at = execution.instance_variable_get(:@started_at)
    execution.add_queue_time(1)
    assert(section = execution.sections[0])
    assert_equal("queue", section.kind)
    assert_equal("queue", section.file)
    assert_equal(0, section.line)
    assert_equal(1, section.calls)
    assert_equal(1, section.total_ms)
    assert_equal(0, section.children_ms)
    assert_equal(0, section.gc_time_ms)
    assert_equal(0, section.async_ms)
    assert_equal(old_started_at - 1, execution.instance_variable_get(:@started_at))
  end

  def test_as_json
    agent.start_execution(execution = RorVsWild::Execution::Job.new("job", [1, 2, 3]))
    agent.measure_section("section") { }
    execution.stop
    json = execution.as_json
    assert_kind_of(Array, sections = json.delete(:sections))
    assert_equal("job", json[:name])
    assert_equal(execution.runtime, json[:runtime])
    assert_nil(json[:error])
    assert_kind_of(Hash, json[:environment])
  end
end
