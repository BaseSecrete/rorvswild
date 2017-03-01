require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWildTest < Minitest::Test
  include TopTests

  def test_measure_code
    client.expects(:post_job)
    assert_equal(2, client.measure_code("1 + 1"))
    assert_equal("1 + 1", client.send(:job)[:name])
    assert(client.send(:job)[:runtime] > 0)
  end

  def test_measure_code_when_raising
    client.expects(:post_job)
    assert_raises(RuntimeError) { client.measure_code("raise 'error'") }
    assert_equal(("raise 'error'"), client.send(:job)[:name])
    assert(client.send(:job)[:runtime])
    assert(client.send(:job)[:error])
  end

  def test_mesure_block_when_exception_is_ignored
    client = initialize_client(ignored_exceptions: %w[ZeroDivisionError])
    client.expects(:post_job)
    assert_raises(ZeroDivisionError) { RorVsWild.measure_code("1/0") }
    refute(client.send(:job)[:error])
  end

  def test_measure_code_when_no_client
    RorVsWild.register_client(nil)
    RorVsWild::Client.any_instance.expects(:post_job).never
    assert_equal(2, RorVsWild.measure_code("1+1"))
  end

  def test_measure_block_when_no_client
    RorVsWild.register_client(nil)
    RorVsWild::Client.any_instance.expects(:post_job).never
    assert_equal(2, RorVsWild.measure_block("1+1") { 1+1 })
  end

  def test_measure_block_recursive
    client.expects(:post_job)
    result = RorVsWild.measure_block("1") do
      RorVsWild.measure_block("2") { 1 } + 1
    end
    assert_equal(2, result)
  end

  def test_catch_error
    client.expects(:post_error)
    exception = RorVsWild.catch_error { 1 / 0 }
    assert_equal(ZeroDivisionError, exception.class)
  end

  def test_catch_error_with_extra_details
    client.expects(:post_error)
    exception = RorVsWild.catch_error(foo: "bar") { 1 / 0 }
    assert_equal(ZeroDivisionError, exception.class)
  end

  def test_catch_error_when_no_errors
    client.expects(:post_error).never
    assert_equal(2, RorVsWild.catch_error { 1 + 1 })
  end

  def test_extract_most_relevant_location
    callstack = ["#{ENV["GEM_HOME"]}/lib/sql.rb:1:in `method1'", "/usr/lib/ruby/net/http.rb:2:in `method2'", "/rails/root/app/models/user.rb:3:in `method3'"]
    assert_equal(%w[/app/models/user.rb 3 method3], client.extract_most_relevant_location(callstack))

    assert_equal(["#{ENV["GEM_HOME"]}/lib/sql.rb", "1", "method1"], client.extract_most_relevant_location(["#{ENV["GEM_HOME"]}/lib/sql.rb:1:in `method1'"]))
  end

  def test_extract_most_relevant_location_when_there_is_not_app_root
    client = initialize_client
    callstack = ["#{ENV["GEM_HOME"]}/lib/sql.rb:1:in `method1'", "/usr/lib/ruby/net/http.rb:2:in `method2'", "/rails/root/app/models/user.rb:3:in `method3'"]
    assert_equal(%w[/usr/lib/ruby/net/http.rb 2 method2], client.extract_most_relevant_location(callstack))
  end

  def test_extract_most_relevant_location_when_there_is_no_method_name
    assert_equal(["/foo/bar.rb", "123", nil], client.extract_most_relevant_location(["/foo/bar.rb:123"]))
  end

  def test_extract_most_relevant_location_when_gem_home_is_in_heroku_app_root
    client = initialize_client(app_root: app_root = File.dirname(gem_home = ENV["GEM_HOME"]))
    callstack = ["#{gem_home}/lib/sql.rb:1:in `method1'", "/usr/lib/ruby/net/http.rb:2:in `method2'", "#{app_root}/app/models/user.rb:3:in `method3'"]
    assert_equal(["/app/models/user.rb", "3", "method3"], client.extract_most_relevant_location(callstack))
  end

  def test_extract_most_relevant_location_when_gem_path_is_set_instead_of_gem_home
    original_gem_home, original_gem_path = ENV["GEM_HOME"], ENV["GEM_PATH"]
    ENV["GEM_HOME"], ENV["GEM_PATH"] = "", "/gem/path"

    callstack = ["/gem/path/lib/sql.rb:1:in `method1'", "/usr/lib/ruby/net/http.rb:2:in `method2'", "/rails/root/app/models/user.rb:3:in `method3'"]
    assert_equal(%w[/app/models/user.rb 3 method3], client.extract_most_relevant_location(callstack))
  ensure
    ENV["GEM_HOME"], ENV["GEM_PATH"] = original_gem_home,  original_gem_path
  end

  def test_extract_most_relevant_location_when_gem_path_and_gem_home_are_undefined
    original_gem_home, original_gem_path = ENV["GEM_HOME"], ENV["GEM_PATH"]
    ENV["GEM_HOME"], ENV["GEM_PATH"] = "", ""

    callstack = ["/gem/path/lib/sql.rb:1:in `method1'", "/usr/lib/ruby/net/http.rb:2:in `method2'", "/rails/root/app/models/user.rb:3:in `method3'"]
    assert_equal(%w[/app/models/user.rb 3 method3], client.extract_most_relevant_location(callstack))
  ensure
    ENV["GEM_HOME"], ENV["GEM_PATH"] = original_gem_home,  original_gem_path
  end

  def test_push_query
    client = initialize_client
    client.send(:data)[:queries] = []
    client.send(:push_query, {kind: "sql", file: "file", line: 123, command: "BEGIN", runtime: 10})
    client.send(:push_query, {kind: "sql", file: "file", line: 123, command: "SELECT 1", runtime: 10})
    client.send(:push_query, {kind: "sql", file: "file", line: 123, command: "SELECT 1", runtime: 10})
    client.send(:push_query, {kind: "sql", file: "file", line: 123, command: "COMMIT", runtime: 10})
    assert_equal([{kind: "sql", file: "file", line: 123, command: "SELECT 1", runtime: 40, times: 2}], client.send(:queries))
  end

  def test_after_exception
    exception, controller = nil, stub(session: {}, request: stub(env: ENV))
    begin; 1/0; rescue => exception; end
    assert_raises(ZeroDivisionError) { client.after_exception(exception, controller) }
    assert_equal("ZeroDivisionError", client.send(:request)[:error][:exception])
  end

  def test_after_exception_when_ignored
    client = initialize_client(ignored_exceptions: %w[ZeroDivisionError])
    exception, controller = nil, stub(session: {}, request: stub(env: ENV))
    begin; raise 1/0; rescue => exception; end
    assert_raises(ZeroDivisionError) { client.after_exception(exception, controller) }
    refute(client.send(:request)[:error])
  end

  private

  def client
    @client ||= initialize_client(app_root: "/rails/root")
  end

  def initialize_client(options = {})
    client ||= RorVsWild::Client.new(options)
    client.stubs(:post_request)
    client.stubs(:post_task)
    client
  end
end
