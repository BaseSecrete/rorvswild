require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::LocatorTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_find_most_relevant_file_and_line
    locator = RorVsWild::Locator.new("/rails/root")
    callstack = [
      stub(path: "#{ENV["GEM_HOME"]}/lib/sql.rb", lineno: 1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "/rails/root/app/models/user.rb", lineno: 3),
    ]
    assert_equal(["/app/models/user.rb", 3], locator.find_most_relevant_file_and_line(callstack))

    locations = [stub(path: "#{ENV["GEM_HOME"]}/lib/sql.rb", lineno: 1)]
    assert_equal(["#{ENV["GEM_HOME"]}/lib/sql.rb", 1], locator.find_most_relevant_file_and_line(locations))
  end

  def test_find_most_relevant_file_and_line_when_there_is_no_current_path
    callstack = [
      stub(path: "#{ENV["GEM_HOME"]}/lib/sql.rb", lineno: 1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "/rails/root/app/models/user.rb", lineno: 3),
    ]
    assert_equal(["/usr/lib/ruby/net/http.rb", 2], locator.find_most_relevant_file_and_line(callstack))
  end

  def test_find_most_relevant_file_and_line_when_there_is_no_method_name
    assert_equal(["/foo/bar.rb", 123], locator.find_most_relevant_file_and_line([stub(path: "/foo/bar.rb", lineno:123)]))
  end

  def test_find_most_relevant_file_and_line_when_gem_home_is_in_heroku_app_root
    locator = RorVsWild::Locator.new(app_root = File.dirname(gem_home = ENV["GEM_HOME"]))
    callstack = [
      stub(path: "#{gem_home}/lib/sql.rb", lineno: 1),
      stub(path: "/usr/lib/ruby/net/http.rb", lineno: 2),
      stub(path: "#{app_root}/app/models/user.rb", lineno: 3)
    ]
    assert_equal(["/app/models/user.rb", 3], locator.find_most_relevant_file_and_line(callstack))
  end

  def test_find_most_relevant_file_and_line_from_array_of_strings
    locator = RorVsWild::Locator.new("/rails/root")

    callstack = ["#{ENV["GEM_HOME"]}/lib/sql.rb:1", "/usr/lib/ruby/net/http.rb:2", "/rails/root/app/models/user.rb:3"]
    assert_equal(["/app/models/user.rb", "3"], locator.find_most_relevant_file_and_line_from_array_of_strings(callstack))

    locations = ["#{ENV["GEM_HOME"]}/lib/sql.rb:1"]
    assert_equal(["#{ENV["GEM_HOME"]}/lib/sql.rb", "1"], locator.find_most_relevant_file_and_line_from_array_of_strings(locations))
  end

  def test_find_most_relevant_file_and_line_from_exception_when_exception_has_no_backtrace
    assert_equal(["No backtrace", 1], locator.find_most_relevant_file_and_line_from_exception(StandardError.new))
  end

  def test_find_most_relevant_file_and_line_from_exception_when_backtrace_is_an_empty_array
    (error = StandardError.new).set_backtrace([])
    assert_equal(["No backtrace", 1], locator.find_most_relevant_file_and_line_from_exception(error))
  end

  private

  def locator
    @locator ||= RorVsWild::Locator.new
  end
end
