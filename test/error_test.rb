# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/helper")

require "active_support/core_ext/hash/keys" # Required by ActiveSupport::ExecutionContext.set

class RorVsWild::ErrorTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_extract_context_with_rails_context
    agent
    ActiveSupport::ExecutionContext.set(foo: "bar")
    begin
      raise
    rescue => exception
      error = RorVsWild::Error.new(exception)
      assert_equal({foo: "bar"}, error.extract_context({}))
    end
  end
end
