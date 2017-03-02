require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::ActionViewTest < Minitest::Test
  include RorVsWildAgentHelper

  def test_render_template_callback
    agent.measure_block("test") do
      ActiveSupport::Notifications.instrument("render_template.action_view", {identifier: "template.html.erb"}) do
        ActiveSupport::Notifications.instrument("render_partial.action_view", {identifier: "_partial.html.erb"}) do
          ActiveSupport::Notifications.instrument("render_partial.action_view", {identifier: "_sub_partial.html.erb"}) do
            sleep 0.03
          end
          sleep 0.02
        end
        sleep 0.01
      end
    end

    sections = agent.data[:sections]
    sub_partial, partial, template = sections[0], sections[1], sections[2]
    assert_equal(3, sections.size)

    assert_equal("view", sub_partial.kind)
    assert_equal("_sub_partial.html.erb", sub_partial.command)

    assert_equal("view", partial.kind)
    assert_equal("_partial.html.erb", partial.command)

    assert_equal("view", template.kind)
    assert_equal("template.html.erb", template.command)

    assert(sub_partial.self_runtime > partial.self_runtime)
    assert(partial.self_runtime > template.self_runtime)
    assert(partial.total_runtime < template.total_runtime)
    assert(sub_partial.total_runtime < partial.total_runtime)
  end
end

