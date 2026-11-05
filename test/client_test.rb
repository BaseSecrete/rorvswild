# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::ClientTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_after_fork_discards_connections_and_resets_mutex
    old_mutex = client.instance_variable_get(:@mutex)
    client.instance_variable_set(:@connections, [Object.new])
    client.instance_variable_set(:@connection_count, 1)
    client.instance_variable_set(:@threads, Set.new([Thread.current]))

    RorVsWild.after_fork

    assert_equal([], client.instance_variable_get(:@connections))
    assert_equal(0, client.instance_variable_get(:@connection_count))
    assert_equal(Set.new, client.threads)
    refute_same(old_mutex, client.instance_variable_get(:@mutex))
  end

  def test_process_fork_triggers_after_fork
    skip("Process._fork is required") unless Process.respond_to?(:_fork)

    client.instance_variable_set(:@connections, [Object.new])
    client.instance_variable_set(:@connection_count, 1)

    read, write = IO.pipe
    pid = fork do
      read.close
      write.write(Marshal.dump([
        client.instance_variable_get(:@connections),
        client.instance_variable_get(:@connection_count),
      ]))
      write.close
      exit!
    end
    write.close
    connections, connection_count = Marshal.load(read.read)
    read.close
    Process.wait(pid)

    assert_equal([], connections)
    assert_equal(0, connection_count)
  end

  def client
    agent.client
  end
end
