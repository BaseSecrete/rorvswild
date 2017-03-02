require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::ActiveRecordTest < Minitest::Test
  include RorVsWildClientHelper

  def test_render_template_callback
    line1, line2 = nil
    client = initialize_client(app_root: File.dirname(__FILE__))
    client.measure_block("test") do
      ActiveSupport::Notifications.instrument("sql.active_record", {sql: "SELECT COUNT(*) FROM users"}) do line1 = __LINE__
        sleep 0.01
      end
      2.times do
        ActiveSupport::Notifications.instrument("sql.active_record", {sql: "SELECT * FROM users"}) do line2 = __LINE__
          sleep 0.02
        end
      end
    end

    sections = client.send(:sections)
    sql1, sql2 = sections[0], sections[1]
    assert_equal(2, sections.size)

    assert_equal("sql", sql1.kind)
    assert_equal("SELECT COUNT(*) FROM users", sql1.command)
    assert_equal(line1, sql1.line.to_i)
    assert_equal(1, sql1.calls)
    assert(sql1.self_runtime > 10)

    assert_equal("sql", sql2.kind)
    assert_equal("SELECT * FROM users", sql2.command)
    assert_equal(line2, sql2.line.to_i)
    assert(sql2.self_runtime > 40)
    assert_equal(2, sql2.calls)
  end
end

