require File.expand_path("#{File.dirname(__FILE__)}/../helper")

class RorVsWild::Plugin::MiddlewareTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_callback
    agent # Load agent
    request = { "ORIGINAL_FULLPATH" => "/foo/bar" }
    app = mock(call: nil)
    middleware = RorVsWild::Plugin::Middleware.new(app, nil)
    middleware.stubs(rails_engine_location: ["/rails/lib/engine.rb", 12])
    middleware.call(request)
    assert_equal("/foo/bar", agent.current_data[:path])
    assert_equal(1, agent.current_data[:sections].size)
    assert_equal("Rails::Engine#call", agent.current_data[:sections][0].command)
    assert_nil(agent.current_data[:queue_time])
  end

  def test_queue_time_secs
    agent # Load agent
    request_start = unix_timestamp_seconds - 0.123
    request = {"HTTP_X_REQUEST_START" => request_start.to_s}
    app = mock(call: nil)
    middleware = RorVsWild::Plugin::Middleware.new(app, nil)
    middleware.stubs(rails_engine_location: ["/rails/lib/engine.rb", 12])
    middleware.call(request)
    assert_in_delta(123, agent.current_data[:queue_time], 10)
  end

  def test_queue_time_millis
    agent # Load agent
    request_start = unix_timestamp_seconds * 1000 - 234
    request = { "HTTP_X_QUEUE_START" => request_start.to_s }
    app = mock(call: nil)
    middleware = RorVsWild::Plugin::Middleware.new(app, nil)
    middleware.stubs(rails_engine_location: ["/rails/lib/engine.rb", 12])
    middleware.call(request)
    assert_in_delta(234, agent.current_data[:queue_time], 10)
  end

  def test_queue_time_micros
    agent # Load agent
    request_start = unix_timestamp_seconds * 1_000_000 - 345_000
    request = { "HTTP_X_MIDDLEWARE_START" => request_start.to_s }
    app = mock(call: nil)
    middleware = RorVsWild::Plugin::Middleware.new(app, nil)
    middleware.stubs(rails_engine_location: ["/rails/lib/engine.rb", 12])
    middleware.call(request)
    assert_in_delta(345, agent.current_data[:queue_time], 10)
  end

  private

  def unix_timestamp_seconds
    Time.now.to_f
  end
end
