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
    assert_equal("command1", section1.command)
  end

  def test_merge_with_appendable_command
    section3.merge(section1)
    assert_equal("command3\ncommand1", section3.command)
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
      s.command = "command1"
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
      s.command = "command2"
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
      s.appendable_command = true
      @section3 = s
    end
    @section3
  end
end
