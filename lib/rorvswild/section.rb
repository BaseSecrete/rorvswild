module RorVsWild
  class Section
    attr_reader :started_at
    attr_accessor :kind, :file, :line, :calls, :command, :children_runtime, :total_runtime

    def self.start
      stack.push(section = Section.new)
      section
    end

    def self.stop(&block)
      block.call(section = stack.pop)
      section.total_runtime = (Time.now.utc - section.started_at) * 1000
      RorVsWild.client.add_section(section)
    end

    def self.stack
      RorVsWild.client.data[:section_stack] ||= []
    end

    def self.last
      stack.last
    end

    def initialize
      @calls = 1
      @total_runtime = 0
      @children_runtime = 0
      @started_at = Time.now.utc
    end

    def sibling?(section)
      kind == section.kind && line == section.line && file == section.file
    end

    def merge(section)
      self.calls += section.calls
      self.total_runtime += section.total_runtime
      self.children_runtime += section.children_runtime
    end

    def self_runtime
      total_runtime - children_runtime
    end
  end
end
