# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "view_component"

class RorVsWild::Plugin::ViewComponentTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_render_view_component_callback
    agent.measure_block("test") do
      instrument("render.view_component", {name: "ParentComponent", identifier: "/app/components/parent_component.rb"}) do
        instrument("render.view_component", {name: "ChildComponent", identifier: "/app/components/child_component.rb"}) { sleep 0.02 }
        instrument("render.view_component", {name: "ChildComponent", identifier: "/app/components/child_component.rb"}) { sleep 0.02 }
        sleep 0.01
      end
    end

    sections = current_user_sections
    child, parent = sections[0], sections[1]
    assert_equal(2, sections.size)

    assert_equal("view", child.kind)
    assert_equal("ChildComponent", child.command)
    assert_equal("/app/components/child_component.rb", child.file)
    assert_equal(0, child.line)
    assert_equal(2, child.calls)

    assert_equal("view", parent.kind)
    assert_equal("ParentComponent", parent.command)
    assert_equal("/app/components/parent_component.rb", parent.file)
    assert_equal(0, parent.line)
    assert_equal(1, parent.calls)

    assert(child.self_ms > parent.self_ms)
    assert(child.total_ms < parent.total_ms)
    assert_equal(parent.children_ms, child.self_ms)
  end

  def test_render_view_component_callback_before_3_3_0
    agent.measure_block("test") do
      instrument("render.view_component", {name: "ParentComponent", identifier: "/app/components/parent_component.rb"}) do
        instrument("!render.view_component", {name: "ChildComponent", identifier: "/app/components/child_component.rb"}) { sleep 0.02 }
        instrument("!render.view_component", {name: "ChildComponent", identifier: "/app/components/child_component.rb"}) { sleep 0.02 }
        sleep 0.01
      end
    end

    sections = current_user_sections
    child, parent = sections[0], sections[1]
    assert_equal(2, sections.size)

    assert_equal("view", child.kind)
    assert_equal("ChildComponent", child.command)

    assert_equal("view", parent.kind)
    assert_equal("ParentComponent", parent.command)
  end

  def test_render_without_identifier
    agent.measure_block("test") do
      instrument("render.view_component", {name: "Component", identifier: nil}) { }
    end
    assert_empty(current_user_sections)
  end
end
