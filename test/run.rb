require File.expand_path("#{File.dirname(__FILE__)}/helper")

Dir.glob("**/*_test.rb").each { |file_path| require File.expand_path(file_path) }
