# frozen_string_literal: true

module RorVsWild
  class Section
    attr_reader :started_at, :commands, :gc_offset_ms
    attr_accessor :kind, :file, :line, :calls, :children_runtime, :total_runtime, :gc_time_ms

    def self.start(&block)
      section = Section.new
      block.call(section) if block_given?
      stack && stack.push(section)
      section
    end

    def self.stop(&block)
      return unless stack && section = stack.pop
      block.call(section) if block_given?
      section.gc_time_ms = gc_total_ms - section.gc_offset_ms
      section.total_runtime = (RorVsWild.clock_milliseconds - section.started_at - section.gc_time_ms).round
      current.children_runtime += section.total_runtime if current
      RorVsWild.agent.add_section(section)
    end

    def self.stack
      (data = RorVsWild.agent.current_data) && data[:section_stack]
    end

    def self.current
      (sections = stack) && sections.last
    end

    def self.start_gc_timing
      section = Section.new
      section.calls = GC.count
      section.file, section.line = GC.method(:start).source_location
      section.add_command("GC.start")
      section
    end

    def self.stop_gc_timing(section)
      section.total_runtime = gc_total_ms - section.gc_offset_ms
      section.calls = GC.count - section.calls
      section
    end

    if GC.respond_to?(:total_time)
      def self.gc_total_ms
        GC.total_time / 1_000_000
      end
    else
      def self.gc_total_ms
        (GC::Profiler.total_time * 1000).round
      end
    end

    def initialize
      @started_at = RorVsWild.clock_milliseconds
      @gc_offset_ms = Section.gc_total_ms
      @calls = 1
      @total_runtime = 0
      @children_runtime = 0
      @gc_time_ms = 0
      @kind = "code"
      location = RorVsWild.agent.locator.find_most_relevant_location(caller_locations)
      @file = RorVsWild.agent.locator.relative_path(location.path)
      @line = location.lineno
      @commands = Set.new
    end

    def sibling?(section)
      kind == section.kind && line == section.line && file == section.file
    end

    def merge(section)
      self.calls += section.calls
      self.total_runtime += section.total_runtime
      self.children_runtime += section.children_runtime
      self.gc_time_ms += section.gc_time_ms
      commands.merge(section.commands)
    end

    def self_runtime
      total_runtime - children_runtime
    end

    def as_json(options = nil)
      {calls: calls, total_runtime: total_runtime, children_runtime: children_runtime, kind: kind, started_at: started_at, file: file, line: line, command: command}
    end

    def to_json(options = {})
      as_json.to_json(options)
    end

    def add_command(command)
      commands << command
    end

    COMMAND_MAX_SIZE = 5_000

    def command
      string = @commands.join("\n")
      string.size > COMMAND_MAX_SIZE ? string[0, COMMAND_MAX_SIZE] + " [TRUNCATED]" : string
    end
  end
end
