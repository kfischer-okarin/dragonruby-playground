module Resources
  # Sprite object rendering a resource
  class Sprite
    attr_sprite

    def initialize(resource, values = nil)
      @resource = resource
      attributes_from_hash(values) if values
    end

    def w
      @w || @resource.data[:w]
    end

    def h
      @h || @resource.data[:h]
    end

    def with(values)
      dup.tap { |copy|
        copy.attributes_from_hash(values)
      }
    end

    def path
      @resource.path
    end

    def attributes_from_hash(hash)
      hash.each do |attribute, value|
        send(:"#{attribute}=", value)
      end
    end
  end

  # Add Resources#as_sprite
  module SpriteExtension
    def as_sprite(values = nil)
      self.class.new(self, values)
    end
  end

  Resource.include SpriteExtension
end
