require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::MeasureNestedSectionsTest < Minitest::Test
  include TopTests

  def test_measure_nested_block
    def client.post_job
      parent, child = sections[1], sections[0]
      raise child.command if child.command != "child"
      raise parent.command if parent.command != "parent"
      raise "#{child.self_runtime} < 100" if child.self_runtime <= 20
      raise "#{parent.self_runtime} < 100" if parent.self_runtime <= 10
      raise "#{child.self_runtime} < #{parent.self_runtime}" if child.self_runtime < parent.self_runtime
      raise "#{child.total_runtime} + #{parent.self_runtime} != #{parent.total_runtime}" if child.total_runtime + parent.self_runtime != parent.total_runtime
    end

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
  end

  def test_measure_nested_block_with_exception
    def client.post_job
      raise sections.size.to_s if sections.size != 2
    end

    assert_raises(ZeroDivisionError) do
      client.measure_block("root") do
        client.measure_block("parent") do
          client.measure_block("child") { 1 / 0 }
        end
      end
    end
  end

  private

  def client
    @client ||= initialize_client(app_root: File.dirname(__FILE__))
  end

  def initialize_client(options = {})
    client ||= RorVsWild::Client.new(options)
    client.stubs(:post_request)
    client.stubs(:post_task)
    client
  end
end
