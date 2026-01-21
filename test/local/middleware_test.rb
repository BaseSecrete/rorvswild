# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../helper")
require "rorvswild/local/middleware"

class RorVsWild::Local::MiddlewareTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_editor_url
    middleware = RorVsWild::Local::Middleware.new(nil, {})
    refute(middleware.send(:editor_url))
    middleware.config[:editor_url] = "foo://${path}:${line}"
    assert_equal("foo://${path}:${line}", middleware.send(:editor_url))

    if defined?(ActiveSupport::Editor)
      stub_env("RAILS_EDITOR" => "bar") do
        ActiveSupport::Editor.register("bar", "bar://%s:%d")
        ActiveSupport::Editor.reset
        assert_equal("foo://${path}:${line}", middleware.send(:editor_url))
        middleware.config[:editor_url] = nil
        ActiveSupport::Editor.reset
        assert_equal("bar://${path}:${line}", middleware.send(:editor_url))
      end
    end
  end
end
