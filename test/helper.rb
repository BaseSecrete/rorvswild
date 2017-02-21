path = File.expand_path("#{File.dirname(__FILE__)}/../lib")
$LOAD_PATH.unshift(path)

require "rorvswild"
require "minitest/autorun"
require "mocha/mini_test"
require "top_tests"
