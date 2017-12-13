require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::MeasureNestedSectionsTest < Minitest::Test
  include RorVsWildAgentHelper

  def test_measure_section
    result = agent.measure_block("root") do
      agent.measure_block("parent") do
        sleep 0.01
        agent.measure_block("child") do
          sleep 0.02
          42
        end
      end
    end
    assert_equal(42, result)
    sections = agent.data[:sections]
    parent, child = sections[1], sections[0]
    assert_equal("child", child.command)
    assert_equal("parent", parent.command)
    assert(child.self_runtime >= 20)
    assert(parent.self_runtime >= 10)
    assert(child.self_runtime > parent.self_runtime)
    assert_equal(child.total_runtime + parent.self_runtime, parent.total_runtime)
  end

  def test_measure_section_with_exception
    assert_raises(ZeroDivisionError) do
      agent.measure_block("root") do
        agent.measure_block("parent") do
          agent.measure_block("child") { 1 / 0 }
        end
      end
    end
    assert_equal(2, agent.data[:sections].size)
  end
end
