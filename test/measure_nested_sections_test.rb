require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::MeasureNestedSectionsTest < Minitest::Test
  include RorVsWildClientHelper
  include TopTests

  def test_measure_nested_block
    result = client.measure_block("root") do
      client.measure_block("parent") do
        sleep 0.01
        client.measure_block("child") do
          sleep 0.02
          42
        end
      end
    end
    assert_equal(42, result)
    sections = client.send(:sections)
    parent, child = sections[1], sections[0]
    assert_equal("child", child.command)
    assert_equal("parent", parent.command)
    assert(child.self_runtime > 20)
    assert(parent.self_runtime > 10)
    assert(child.self_runtime > parent.self_runtime)
    assert_equal(child.total_runtime + parent.self_runtime, parent.total_runtime)
  end

  def test_measure_nested_block_with_exception
    assert_raises(ZeroDivisionError) do
      client.measure_block("root") do
        client.measure_block("parent") do
          client.measure_block("child") { 1 / 0 }
        end
      end
    end
    assert_equal(2, client.send(:sections).size)
  end
end
