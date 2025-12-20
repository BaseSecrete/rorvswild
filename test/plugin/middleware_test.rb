require File.expand_path("#{File.dirname(__FILE__)}/../helper")

class RorVsWild::Plugin::MiddlewareTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_callback
    middleware.call("ORIGINAL_FULLPATH" => "/foo/bar")
    assert_equal("/foo/bar", agent.current_execution.path)
    assert_equal(1, (sections = current_user_sections).size)
    assert_equal("Rails::Engine#call", sections[0].command)
  end

  def test_queue_time_section
    middleware.call("HTTP_X_REQUEST_START" => unix_timestamp_seconds.to_s)

    sections = current_user_sections
    assert_equal(2, sections.size)
    queue_time_section = sections[0]
    assert_equal "queue", queue_time_section.file
    assert_equal "queue", queue_time_section.kind
    assert_equal 0, queue_time_section.line
    assert_equal 0, queue_time_section.gc_time_ms
  end

  def test_queue_time_secs
    middleware.call("HTTP_X_REQUEST_START" => (unix_timestamp_seconds - 0.123).to_s)

    sections = current_user_sections
    assert_equal(2, sections.size)
    assert_operator(123, :<=, sections[0].total_ms)
  end

  def test_queue_time_millis
    middleware.call("HTTP_X_QUEUE_START" => (unix_timestamp_seconds * 1000 - 234).to_s)

    sections = current_user_sections
    assert_equal(2, sections.size)
    assert_operator(234, :<=, sections[0].total_ms)
  end

  def test_queue_time_micros
    middleware.call("HTTP_X_MIDDLEWARE_START" => (unix_timestamp_seconds * 1_000_000 - 345_000).to_s)

    sections = current_user_sections
    assert_equal(2, sections.size)
    assert_operator(345, :<=, sections[0].total_ms)
  end

  private

  def unix_timestamp_seconds
    Time.now.to_f
  end

  def middleware
    agent # Load agent
    app = mock(call: nil)
    middleware = RorVsWild::Plugin::Middleware.new(app, nil)
    middleware.stubs(rails_engine_location: ["/rails/lib/engine.rb", 12])
    middleware
  end
end
