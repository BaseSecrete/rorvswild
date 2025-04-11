# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::RailsCacheTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_instrumentations_read_and_write
    line1, line2 = nil
    agent.locator.stubs(current_path: File.dirname(__FILE__))
    agent.measure_block("test") do
      ActiveSupport::Notifications.instrument("cache_write.active_support", {}) do line1 = __LINE__
        sleep 0.01
      end
      2.times do
        ActiveSupport::Notifications.instrument("cache_read.active_support", {}) do line2 = __LINE__
          sleep 0.02
        end
      end
    end

    sections = current_sections_without_gc
    cache1, cache2 = sections[0], sections[1]
    assert_equal(2, sections.size)

    assert_equal("cache", cache1.kind)
    assert_equal("write", cache1.command)
    assert_equal(line1, cache1.line.to_i)
    assert_equal(1, cache1.calls)
    assert(cache1.self_ms >= 10)

    assert_equal("cache", cache2.kind)
    assert_equal("read", cache2.command)
    assert_equal(line2, cache2.line.to_i)
    assert(cache2.self_ms >= 40)
    assert_equal(2, cache2.calls)
  end
end
