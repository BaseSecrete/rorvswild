module RorVsWild
  class Section
    attr_accessor :kind, :file, :line, :calls, :command, :children_runtime, :total_runtime

    def initialize
      @calls = 1
      @total_runtime = 0
      @children_runtime = 0
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
