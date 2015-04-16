root_path = File.expand_path(File.dirname(File.dirname(__FILE__)))
$LOAD_PATH.unshift(root_path + "/lib")

require "rorvswild"

require "minitest/autorun"
require 'mocha/mini_test'
require "top_tests"

class RorVsWildTest < MiniTest::Unit::TestCase
  include TopTests

  def test_measure_code
    client.expects(:post_job)
    assert_equal(2, client.measure_code("1 + 1"))
    assert_equal("1 + 1", client.send(:job)[:name])
    assert(client.send(:job)[:runtime] > 0)
    assert_equal(0, client.send(:job)[:cpu_runtime])
  end

  def test_measure_code_when_raising
    client.expects(:post_job)
    assert_raises(RuntimeError) { client.measure_code("raise 'error'") }
    assert_equal(("raise 'error'"), client.send(:job)[:name])
    assert(client.send(:job)[:cpu_runtime])
    assert(client.send(:job)[:runtime])
    assert(client.send(:job)[:error])
  end

  def test_measure_code_when_no_client
    RorVsWild.register_default_client(nil)
    RorVsWild::Client.any_instance.expects(:post_job).never
    assert_equal(2, RorVsWild.measure_code("1+1"))
  end

  def test_measure_block_when_no_client
    RorVsWild.register_default_client(nil)
    RorVsWild::Client.any_instance.expects(:post_job).never
    assert_equal(2, RorVsWild.measure_block("1+1") { 1+1 })
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
    assert_equal(%w[/app/models/user.rb 3 method3], client.send(:extract_most_relevant_location, callstack))

    assert_equal(["#{ENV["GEM_HOME"]}/lib/sql.rb", "1", "method1"], client.send(:extract_most_relevant_location, ["#{ENV["GEM_HOME"]}/lib/sql.rb:1:in `method1'"]))
  end

  def test_extract_most_relevant_location_when_there_is_not_app_root
    client = initialize_client
    callstack = ["#{ENV["GEM_HOME"]}/lib/sql.rb:1:in `method1'", "/usr/lib/ruby/net/http.rb:2:in `method2'", "/rails/root/app/models/user.rb:3:in `method3'"]
    assert_equal(%w[/usr/lib/ruby/net/http.rb 2 method2], client.send(:extract_most_relevant_location, callstack))
  end

  def test_extract_most_relevant_location_when_there_is_no_method_name
    assert_equal(["/foo/bar.rb", "123", nil], client.send(:extract_most_relevant_location, ["/foo/bar.rb:123"]))
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
