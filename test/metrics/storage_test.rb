require File.expand_path("#{File.dirname(__FILE__)}/../helper")

class RorVsWild::Metrics::StorageTest < Minitest::Test
  def test_total
    storage = RorVsWild::Metrics::Storage.new
    storage.update

    assert(storage.total > 0)
    assert(storage.total > storage.free)
    assert(storage.total > storage.used)
  end
end
