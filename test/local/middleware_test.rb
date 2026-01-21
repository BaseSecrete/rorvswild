# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../helper")
require "rorvswild/local/middleware"

class RorVsWild::Local::MiddlewareTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_editor_url_from_config
    middleware = build_middleware(editor_url: "vscode://file${path}:${line}")
    assert_equal("vscode://file${path}:${line}", middleware.send(:editor_url))
  end

  def test_editor_url_empty_config_falls_back_to_rails
    middleware = build_middleware(editor_url: "")

    # Create a simple editor object with url_for method
    mock_editor = Object.new
    def mock_editor.url_for(path, line)
      "vscode://file/#{path}:#{line}"
    end

    Object.stub_const(:ActiveSupport, Module.new) do
      ActiveSupport.const_set(:Editor, Class.new)
      ActiveSupport::Editor.stubs(:current).returns(mock_editor)

      assert_equal("vscode://file/${path}:${line}", middleware.send(:editor_url))
    end
  end

  def test_editor_url_nil_config_falls_back_to_rails
    middleware = build_middleware(editor_url: nil)

    # Create a simple editor object with url_for method
    mock_editor = Object.new
    def mock_editor.url_for(path, line)
      "subl://open?url=file://#{path}&line=#{line}"
    end

    Object.stub_const(:ActiveSupport, Module.new) do
      ActiveSupport.const_set(:Editor, Class.new)
      ActiveSupport::Editor.stubs(:current).returns(mock_editor)

      assert_equal("subl://open?url=file://${path}&line=${line}", middleware.send(:editor_url))
    end
  end

  def test_editor_url_without_rails_editor
    middleware = build_middleware(editor_url: nil)

    # Without ActiveSupport::Editor defined, should return nil
    assert_nil(middleware.send(:editor_url))
  end

  def test_editor_url_when_rails_editor_returns_nil
    middleware = build_middleware(editor_url: nil)

    Object.stub_const(:ActiveSupport, Module.new) do
      ActiveSupport.const_set(:Editor, Class.new)
      ActiveSupport::Editor.stubs(:current).returns(nil)

      assert_nil(middleware.send(:editor_url))
    end
  end

  def test_editor_url_config_takes_precedence_over_rails
    middleware = build_middleware(editor_url: "custom://editor/${path}:${line}")

    Object.stub_const(:ActiveSupport, Module.new) do
      ActiveSupport.const_set(:Editor, Class.new)
      # Even if Rails editor is available, config should take precedence
      ActiveSupport::Editor.stubs(:current).returns(Object.new)

      assert_equal("custom://editor/${path}:${line}", middleware.send(:editor_url))
    end
  end

  def test_rails_editor_url_handles_exception
    middleware = build_middleware(editor_url: nil)

    Object.stub_const(:ActiveSupport, Module.new) do
      ActiveSupport.const_set(:Editor, Class.new)
      ActiveSupport::Editor.stubs(:current).raises(StandardError.new("test error"))

      assert_nil(middleware.send(:rails_editor_url))
    end
  end

  private

  def build_middleware(editor_url:)
    agent
    RorVsWild.agent.config[:editor_url] = editor_url
    app = Object.new
    def app.call(env); [200, {}, []]; end
    RorVsWild::Local::Middleware.new(app, RorVsWild.agent.config)
  end
end
