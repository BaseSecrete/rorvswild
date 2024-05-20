require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::SectionTest < Minitest::Test
  include RorVsWild::AgentHelper

  def setup
    agent
  end

  def test_sibling?
    refute(section1.sibling?(section2))
    refute(section2.sibling?(section1))

    section2.line = section1.line
    assert(section1.sibling?(section2))
    assert(section2.sibling?(section1))
  end

  def test_merge
    section1.merge(section2)
    assert_equal(3, section1.calls)
    assert_equal(3, section1.total_runtime)
    assert_equal(3, section1.children_runtime)
    assert_equal("command1\ncommand2", section1.command)
  end

  def test_section_command_setter
    section = RorVsWild::Section.new
    section.add_command(" " * 6_000)
    assert_equal(" " * 5_000 + " [TRUNCATED]", section.command)
  end

  def test_gc_time_ms
    GC::Profiler.enable
    agent.measure_job("job") do
      agent.measure_section("section") { GC.start; GC.start }
    end
    agent.stop_request
    section, gc = agent.current_data[:sections]
    assert(section.self_runtime < section.gc_time_ms)
    assert_equal(gc.total_runtime, section.gc_time_ms)
    assert_equal(2, gc.calls)
  end

  def section1
    unless @section1
      s = RorVsWild::Section.new
      s.kind = "test"
      s.file = "file"
      s.line = 1
      s.calls = 1
      s.total_runtime = 1
      s.children_runtime = 1
      s.add_command("command1")
      @section1 = s
    end
    @section1
  end

  def section2
    unless @section2
      s = RorVsWild::Section.new
      s.kind = "test"
      s.file = "file"
      s.line = 2
      s.calls = 2
      s.total_runtime = 2
      s.children_runtime = 2
      s.add_command("command2")
      @section2 = s
    end
    @section2
  end

  def section3
    unless @section3
      s = RorVsWild::Section.new
      s.kind = "test"
      s.file = "file"
      s.line = 3
      s.calls = 0
      s.total_runtime = 3
      s.children_runtime = 3
      s.command = "command3"
      @section3 = s
    end
    @section3
  end
end
