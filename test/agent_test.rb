require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::AgentTest < Minitest::Test
  include RorVsWild::AgentHelper

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

  def test_measure_job_when_ignored
    result = agent.measure_job("SecretJob") { "result" }
    assert_equal("result", result)
    refute(agent.data[:name])
  end

  def test_extract_most_relevant_file_and_line
    agent = initialize_agent(app_root: "/rails/root")
    callstack = [
      stub(path: "#{ENV["GEM_HOME"]}/lib/sql.rb", lineno: 1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "/rails/root/app/models/user.rb", lineno: 3),
    ]
    assert_equal(["/app/models/user.rb", 3], agent.extract_most_relevant_file_and_line(callstack))

    locations = [stub(path: "#{ENV["GEM_HOME"]}/lib/sql.rb", lineno: 1)]
    assert_equal(["#{ENV["GEM_HOME"]}/lib/sql.rb", 1], agent.extract_most_relevant_file_and_line(locations))
  end

  def test_extract_most_relevant_file_and_line_when_there_is_not_app_root
    agent = initialize_agent
    callstack = [
      stub(path: "#{ENV["GEM_HOME"]}/lib/sql.rb", lineno: 1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "/rails/root/app/models/user.rb", lineno: 3),
    ]
    assert_equal(["/usr/lib/ruby/net/http.rb", 2], agent.extract_most_relevant_file_and_line(callstack))
  end

  def test_extract_most_relevant_file_and_line_when_there_is_no_method_name
    assert_equal(["/foo/bar.rb", 123], agent.extract_most_relevant_file_and_line([stub(path: "/foo/bar.rb", lineno:123)]))
  end

  def test_extract_most_relevant_file_and_line_when_gem_home_is_in_heroku_app_root
    agent = initialize_agent(app_root: app_root = File.dirname(gem_home = ENV["GEM_HOME"]))
    callstack = [
      stub(path: "#{gem_home}/lib/sql.rb", lineno: 1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "#{app_root}/app/models/user.rb", lineno: 3)
    ]
    assert_equal(["/app/models/user.rb", 3], agent.extract_most_relevant_file_and_line(callstack))
  end

  def test_extract_most_relevant_file_and_line_when_gem_path_is_set_instead_of_gem_home
    original_gem_home, original_gem_path = ENV["GEM_HOME"], ENV["GEM_PATH"]
    ENV["GEM_HOME"], ENV["GEM_PATH"] = "", "/gem/path"
    agent = initialize_agent(app_root: "/rails/root")

    callstack = [
      stub(path: "/gem/path/lib/sql.rb", lineno:1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "/rails/root/app/models/user.rb",lineno: 3),
    ]
    assert_equal(["/app/models/user.rb", 3], agent.extract_most_relevant_file_and_line(callstack))
  ensure
    ENV["GEM_HOME"], ENV["GEM_PATH"] = original_gem_home,  original_gem_path
  end

  def test_extract_most_relevant_file_and_line_when_gem_path_and_gem_home_are_undefined
    original_gem_home, original_gem_path = ENV["GEM_HOME"], ENV["GEM_PATH"]
    ENV["GEM_HOME"], ENV["GEM_PATH"] = "", ""
    agent = initialize_agent(app_root: "/rails/root")

    callstack = [
      stub(path: "/gem/path/lib/sql.rb", lineno: 1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "/rails/root/app/models/user.rb", lineno: 3),
    ]
    assert_equal(["/app/models/user.rb", 3], agent.extract_most_relevant_file_and_line(callstack))
  ensure
    ENV["GEM_HOME"], ENV["GEM_PATH"] = original_gem_home,  original_gem_path
  end

  def test_extract_most_relevant_file_and_line_from_array_of_strings
    agent = initialize_agent(app_root: "/rails/root")

    callstack = ["#{ENV["GEM_HOME"]}/lib/sql.rb:1", "/usr/lib/ruby/net/http.rb:2", "/rails/root/app/models/user.rb:3"]
    assert_equal(["/app/models/user.rb", "3"], agent.extract_most_relevant_file_and_line_from_array_of_strings(callstack))

    locations = ["#{ENV["GEM_HOME"]}/lib/sql.rb:1"]
    assert_equal(["#{ENV["GEM_HOME"]}/lib/sql.rb", "1"], agent.extract_most_relevant_file_and_line_from_array_of_strings(locations))
  end

  def test_extract_most_relevant_file_and_line_from_exception_when_exception_has_no_backtrace
    assert_equal(["No backtrace", 1], agent.extract_most_relevant_file_and_line_from_exception(StandardError.new))
  end

  def test_extract_most_relevant_file_and_line_from_exception_when_backtrace_is_an_empty_array
    (error = StandardError.new).set_backtrace([])
    assert_equal(["No backtrace", 1], agent.extract_most_relevant_file_and_line_from_exception(error))
  end
end
