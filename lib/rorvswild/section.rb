# frozen_string_literal: true

module RorVsWild
  class Section
    attr_reader :start_ms, :commands, :gc_start_ms
    attr_accessor :kind, :file, :line, :calls, :children_ms, :total_ms, :gc_time_ms

    def self.start(&block)
      section = Section.new
      block.call(section) if block_given?
      stack && stack.push(section)
      section
    end

    def self.stop(&block)
      return unless stack && section = stack.pop
      block.call(section) if block_given?
      section.stop
      current.children_ms += section.total_ms if current
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
      section.file, section.line = "ruby/gc.c", 42
      section.add_command("GC.start")
      section.kind = "gc"
      section
    end

    def self.stop_gc_timing(section)
      section.total_ms = gc_total_ms - section.gc_start_ms
      section.calls = GC.count - section.calls
      section
    end

    if GC.respond_to?(:total_time)
      def self.gc_total_ms
        GC.total_time / 1_000_000.0 # nanosecond -> millisecond
      end
    else
      def self.gc_total_ms
        GC::Profiler.total_time * 1000 # second -> millisecond
      end
    end

    def initialize
      @start_ms = RorVsWild.clock_milliseconds
      @end_ms = nil
      @gc_start_ms = Section.gc_total_ms
      @gc_end_ms = nil
      @gc_time_ms = 0
      @calls = 1
      @total_ms = 0
      @children_ms = 0
      @kind = "code"
      location = RorVsWild.agent.locator.find_most_relevant_location(caller_locations)
      @file = RorVsWild.agent.locator.relative_path(location.path)
      @line = location.lineno
      @commands = Set.new
    end

    def stop
      @gc_end_ms = self.class.gc_total_ms
      @gc_time_ms = @gc_end_ms - @gc_start_ms
      @end_ms = RorVsWild.clock_milliseconds
      @total_ms = @end_ms - @start_ms - gc_time_ms
    end

    def sibling?(section)
      kind == section.kind && line == section.line && file == section.file
    end

    def merge(section)
      self.calls += section.calls
      self.total_ms += section.total_ms
      self.children_ms += section.children_ms
      self.gc_time_ms += section.gc_time_ms
      commands.merge(section.commands)
    end

    def self_ms
      total_ms - children_ms
    end

    def as_json(options = nil)
      {calls: calls, total_runtime: total_ms, children_runtime: children_ms, kind: kind, started_at: start_ms, file: file, line: line, command: command}
    end

    def to_json(options = {})
      as_json.to_json(options)
    end

    def add_command(command)
      commands << command
    end

    COMMAND_MAX_SIZE = 5_000

    def command
      string = @commands.to_a.join("\n")
      string.size > COMMAND_MAX_SIZE ? string[0, COMMAND_MAX_SIZE] + " [TRUNCATED]" : string
    end
  end
end
