module RorVsWild
  class Section
    attr_reader :started_at
    attr_accessor :kind, :file, :line, :calls, :command, :children_runtime, :total_runtime, :appendable_command

    def self.start(&block)
      section = Section.new
      block.call(section) if block_given?
      stack.push(section)
      section
    end

    def self.stop(&block)
      section = stack.pop
      block.call(section) if block_given?
      section.total_runtime = RorVsWild.clock_milliseconds - section.started_at
      current.children_runtime += section.total_runtime if current
      RorVsWild.agent.add_section(section)
    end

    def self.stack
      RorVsWild.agent.data[:section_stack] ||= []
    end

    def self.current
      stack.last
    end

    def initialize
      @calls = 1
      @total_runtime = 0
      @children_runtime = 0
      @started_at = RorVsWild.clock_milliseconds
      location = RorVsWild.agent.find_most_relevant_location(caller_locations)
      @file = RorVsWild.agent.relative_path(location.path)
      @line = location.lineno
      @appendable_command = false
    end

    def sibling?(section)
      kind == section.kind && line == section.line && file == section.file
    end

    def merge(section)
      self.calls += section.calls
      self.total_runtime += section.total_runtime
      self.children_runtime += section.children_runtime
      if section
        if appendable_command
          self.command = self.command.dup if self.command.frozen?
          self.command << "\n" + section.command
        end
      else
        self.command = section.command
      end
      self.appendable_command = appendable_command && section.appendable_command
    end

    def self_runtime
      total_runtime - children_runtime
    end

    COMMAND_MAX_SIZE = 1000

    def command=(value)
      @command = value && value.size > COMMAND_MAX_SIZE ? value[0, COMMAND_MAX_SIZE] + " [TRUNCATED]" : value
    end
  end
end
