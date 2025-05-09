require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::ActionViewTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_render_template_callback
    agent.measure_block("test") do
      instrument("render_template.action_view", {identifier: "template.html.erb"}) do
        instrument("render_partial.action_view", {identifier: "_partial.html.erb"}) do
          instrument("render_partial.action_view", {identifier: "_sub_partial.html.erb"}) do
            sleep 0.03
          end
          sleep 0.02
        end
        sleep 0.01
      end
    end

    sections = current_sections_without_gc
    sub_partial, partial, template = sections[0], sections[1], sections[2]
    assert_equal(3, sections.size)

    assert_equal("view", sub_partial.kind)
    assert_equal("_sub_partial.html.erb", sub_partial.command)
    assert_equal(1, sub_partial.calls)

    assert_equal("view", partial.kind)
    assert_equal("_partial.html.erb", partial.command)
    assert_equal(1, partial.calls)

    assert_equal("view", template.kind)
    assert_equal("template.html.erb", template.command)
    assert_equal(1, template.calls)

    assert(sub_partial.self_ms > partial.self_ms)
    assert(partial.self_ms > template.self_ms)
    assert(partial.total_ms < template.total_ms)
    assert(sub_partial.total_ms < partial.total_ms)
  end

  def test_render_collection
    agent.measure_block("test") do
      instrument("render_template.action_view", {identifier: "template.html.erb"}) do
        instrument("render_collection.action_view", {identifier: "_collection.html.erb", count: 10}) { }
        instrument("render_collection.action_view", {identifier: "_collection.html.erb", count: 5}) { }
      end
    end

    sections = current_sections_without_gc
    collection, template = sections[0], sections[1]
    assert_equal(2, sections.size)

    assert_equal("view", template.kind)
    assert_equal("template.html.erb", template.command)
    assert_equal(1, template.calls)

    assert_equal("view", collection.kind)
    assert_equal("_collection.html.erb", collection.command)
    assert_equal(15, collection.calls)
  end

  def test_render_empty_collection
    agent.measure_block("test") do
      instrument("render_template.action_view", {identifier: "_collection.html.erb", layout: nil, count: 0}) { }
    end
    assert_empty(current_sections_without_gc)
  end

  def test_render_withtout_identifier
    agent.measure_block("test") do
      instrument("render_template.action_view", {identifier: nil}) { }
    end
    assert_empty(current_sections_without_gc)
  end

  private

  def instrument(*args, &block)
    ActiveSupport::Notifications.instrument(*args, &block)
  end
end
