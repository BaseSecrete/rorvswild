require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::HostTest < Minitest::Test
  def test_format_header_name
    assert_equal("Content-Type", RorVsWild::Error.format_header_name("HTTP_CONTENT_TYPE"))
  end
end
