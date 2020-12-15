# Manages resources (and their credits if necessary)
module Resources
  # Minimal set implementation
  class Set
    def initialize(*elements)
      @values = {}
      elements.each do |element|
        self << element
      end
    end

    def <<(element)
      @values[element] = true
    end

    def include?(element)
      @values.key? element
    end
  end

  # Path and metadata of a single resource
  class Resource
    attr_reader :path, :data

    def initialize(path, data = nil)
      @path = path
      @data = data || {}
    end

    def inspect
      @path[10..-5]
    end
  end

  # Mixin for group defining behaviour (used in both Resources root and groups themselves)
  module ContainingResourceGroup
    def group(name, extension = nil, &block)
      @groups ||= {}
      @groups[name] = ResourceGroup.new(name, self, extension || self.extension)
      @groups[name].instance_eval(&block)

      define_singleton_method name do
        @groups[name]
      end
    end
  end

  # Easy access for resources like this:
  # Resources.fonts.vector
  class ResourceGroup
    include ContainingResourceGroup

    RESERVED_NAMES = Set.new(:name, :extension, :add, :initialize, :group)

    attr_reader :name, :extension

    def initialize(name, parent, extension)
      @name = "#{parent.name}/#{name}"
      @extension = extension
      @resources = {}
    end

    def add(key, resource_data = nil)
      raise "Cannot define resource with reserved name '#{key}'" if RESERVED_NAMES.include? key

      path = "#{@name}/#{key}.#{extension}"
      @resources[key] = Resource.new(path, resource_data)
      define_singleton_method key do
        @resources[key]
      end
    end
  end

  class << self
    include ContainingResourceGroup

    def name
      @root_folder
    end

    def extension
      nil
    end
  end

  @root_folder = 'resources'
end
