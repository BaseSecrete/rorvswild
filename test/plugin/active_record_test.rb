# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::ActiveRecordTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_render_template_callback
    line1, line2 = nil
    agent.locator.stubs(current_path: File.dirname(__FILE__))
    agent.measure_block("test") do
      ActiveSupport::Notifications.instrument("sql.active_record", {sql: "SELECT COUNT(*) FROM users"}) do line1 = __LINE__
        sleep 0.01
      end
      2.times do
        ActiveSupport::Notifications.instrument("sql.active_record", {sql: "SELECT * FROM users"}) do line2 = __LINE__
          sleep 0.02
        end
      end
    end

    sections = current_sections_without_gc
    sql1, sql2 = sections[0], sections[1]
    assert_equal(2, sections.size)

    assert_equal("sql", sql1.kind)
    assert_equal("SELECT COUNT(*) FROM users", sql1.command)
    assert_equal(line1, sql1.line.to_i)
    assert_equal(1, sql1.calls)
    assert(sql1.self_runtime >= 10)

    assert_equal("sql", sql2.kind)
    assert_equal("SELECT * FROM users", sql2.command)
    assert_equal(line2, sql2.line.to_i)
    assert(sql2.self_runtime >= 40)
    assert_equal(2, sql2.calls)
  end

  def test_transaction_begin_insert_into_and_commit
    agent.locator.stubs(current_path: File.dirname(__FILE__))
    agent.measure_block("test") do
      3.times do
        instrument_sql("BEGIN")
        instrument_sql("INSERT INTO users")
        instrument_sql("COMMIT")
      end
    end
    sections = current_sections_without_gc
    assert_equal(1, sections.size)
    assert_equal(9, sections[0].calls)
    assert_equal("BEGIN\nINSERT INTO users\nCOMMIT", sections[0].command)
  end

  def test_normalize_sql_query
    plugin = RorVsWild::Plugin::ActiveRecord.new
    assert_equal("", plugin.normalize_sql_query(nil))
    assert_equal("?", plugin.normalize_sql_query(1))
    assert_equal("", plugin.normalize_sql_query(""))
    assert_equal("SELECT * FROM table WHERE col = ?", plugin.normalize_sql_query("SELECT * FROM table WHERE col = $1"))
    assert_equal("SELECT * FROM table WHERE col1 = ?", plugin.normalize_sql_query("SELECT * FROM table WHERE col1 = 1"))
    assert_equal("SELECT * FROM table WHERE col = ?", plugin.normalize_sql_query("SELECT * FROM table WHERE col = 1.3"))
    assert_equal("SELECT * FROM table WHERE col = ?", plugin.normalize_sql_query("SELECT * FROM table WHERE col = 'foo'"))
    assert_equal("SELECT * FROM table WHERE col = ?", plugin.normalize_sql_query("SELECT * FROM table WHERE col = 'J''aime l''avion l''été'"))
    assert_equal("SELECT * FROM table WHERE col = ?", plugin.normalize_sql_query("SELECT * FROM table WHERE col = 'J\\'aime l\\'avion l\\'été'"))
    assert_equal("SELECT * FROM table WHERE col >= ? + pow(? * ?, ? + ?) + length(?)", plugin.normalize_sql_query("SELECT * FROM table WHERE col >= ? + pow($1 * 2, 3 + 4) + length('foo')"))
    assert_equal("SELECT * FROM table WHERE col1 IN (?) AND col2 in (?)", plugin.normalize_sql_query("SELECT * FROM table WHERE col1 IN ('foo', 'bar') AND col2 in (1,2)"))
    assert_equal("SELECT * FROM table", plugin.normalize_sql_query("SELECT * FROM table -- Comment"))
    assert_equal("SELECT ? FROM table col = ?", plugin.normalize_sql_query("SELECT 'Test'/* 'Comment' 1 */ FROM table /* Comment 2 */col = /* Comment 3 */1"))
  end

  private

  def instrument_sql(query)
    ActiveSupport::Notifications.instrument("sql.active_record", {sql: query}) { }
  end
end

