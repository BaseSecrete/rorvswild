require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWildTest < Minitest::Test
  include TopTests

  def test_measure_code
    agent.expects(:post_job)
    assert_equal(2, agent.measure_code("1 + 1"))
    assert_equal("1 + 1", agent.send(:data)[:name])
    assert(agent.send(:data)[:runtime] > 0)
  end

  def test_measure_code_when_raising
    agent.expects(:post_job)
    assert_raises(RuntimeError) { agent.measure_code("raise 'error'") }
    assert_equal(("raise 'error'"), agent.send(:data)[:name])
    assert(agent.send(:data)[:runtime])
    assert(agent.send(:data)[:error])
  end

  def test_mesure_block_when_exception_is_ignored
    agent = initialize_agent(ignored_exceptions: %w[ZeroDivisionError])
    agent.expects(:post_job)
    assert_raises(ZeroDivisionError) { RorVsWild.measure_code("1/0") }
    refute(agent.send(:data)[:error])
  end

  def test_measure_code_when_no_agent
    RorVsWild.instance_variable_set(:@agent, nil)
    RorVsWild::Agent.any_instance.expects(:post_job).never
    assert_equal(2, RorVsWild.measure_code("1+1"))
  end

  def test_measure_block_when_no_agent
    RorVsWild.instance_variable_set(:@agent, nil)
    RorVsWild::Agent.any_instance.expects(:post_job).never
    assert_equal(2, RorVsWild.measure_block("1+1") { 1+1 })
  end

  def test_measure_block_recursive
    agent.expects(:post_job)
    result = RorVsWild.measure_block("1") do
      RorVsWild.measure_block("2") { 1 } + 1
    end
    assert_equal(2, result)
  end

  def test_catch_error
    agent.expects(:post_error)
    exception = RorVsWild.catch_error { 1 / 0 }
    assert_equal(ZeroDivisionError, exception.class)
  end

  def test_catch_error_with_extra_details
    agent.expects(:post_error)
    exception = RorVsWild.catch_error(foo: "bar") { 1 / 0 }
    assert_equal(ZeroDivisionError, exception.class)
  end

  def test_catch_error_when_no_errors
    agent.expects(:post_error).never
    assert_equal(2, RorVsWild.catch_error { 1 + 1 })
  end

  def test_extract_most_relevant_location
    callstack = [
      stub(path: "#{ENV["GEM_HOME"]}/lib/sql.rb", lineno: 1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "/rails/root/app/models/user.rb", lineno: 3),
    ]
    assert_equal(["/app/models/user.rb", 3], agent.extract_most_relevant_location(callstack))

    locations = [stub(path: "#{ENV["GEM_HOME"]}/lib/sql.rb", lineno: 1)]
    assert_equal(["#{ENV["GEM_HOME"]}/lib/sql.rb", 1], agent.extract_most_relevant_location(locations))
  end

  def test_extract_most_relevant_location_when_there_is_not_app_root
    agent = initialize_agent
    callstack = [
      stub(path: "#{ENV["GEM_HOME"]}/lib/sql.rb", lineno: 1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "/rails/root/app/models/user.rb", lineno: 3),
    ]
    assert_equal(["/usr/lib/ruby/net/http.rb", 2], agent.extract_most_relevant_location(callstack))
  end

  def test_extract_most_relevant_location_when_there_is_no_method_name
    assert_equal(["/foo/bar.rb", 123], agent.extract_most_relevant_location([stub(path: "/foo/bar.rb", lineno:123)]))
  end

  def test_extract_most_relevant_location_when_gem_home_is_in_heroku_app_root
    agent = initialize_agent(app_root: app_root = File.dirname(gem_home = ENV["GEM_HOME"]))
    callstack = [
      stub(path: "#{gem_home}/lib/sql.rb", lineno: 1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "#{app_root}/app/models/user.rb", lineno: 3)
    ]
    assert_equal(["/app/models/user.rb", 3], agent.extract_most_relevant_location(callstack))
  end

  def test_extract_most_relevant_location_when_gem_path_is_set_instead_of_gem_home
    original_gem_home, original_gem_path = ENV["GEM_HOME"], ENV["GEM_PATH"]
    ENV["GEM_HOME"], ENV["GEM_PATH"] = "", "/gem/path"

    callstack = [
      stub(path: "/gem/path/lib/sql.rb", lineno:1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "/rails/root/app/models/user.rb",lineno: 3),
    ]
    assert_equal(["/app/models/user.rb", 3], agent.extract_most_relevant_location(callstack))
  ensure
    ENV["GEM_HOME"], ENV["GEM_PATH"] = original_gem_home,  original_gem_path
  end

  def test_extract_most_relevant_location_when_gem_path_and_gem_home_are_undefined
    original_gem_home, original_gem_path = ENV["GEM_HOME"], ENV["GEM_PATH"]
    ENV["GEM_HOME"], ENV["GEM_PATH"] = "", ""

    callstack = [
      stub(path: "/gem/path/lib/sql.rb", lineno: 1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "/rails/root/app/models/user.rb", lineno: 3),
    ]
    assert_equal(["/app/models/user.rb", 3], agent.extract_most_relevant_location(callstack))
  ensure
    ENV["GEM_HOME"], ENV["GEM_PATH"] = original_gem_home,  original_gem_path
  end

  private

  def agent
    @agent ||= initialize_agent(app_root: "/rails/root")
  end

  def initialize_agent(options = {})
    agent ||= RorVsWild.start(options)
    agent.stubs(:post_request)
    agent.stubs(:post_task)
    agent
  end
end
