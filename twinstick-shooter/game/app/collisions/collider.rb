class Collisions
  class CompositeCollider
    def initialize(colliders)
      @colliders = colliders
    end

    def collides_with?(other)
      @colliders.any? { |collider| collider.collides_with?(other) }
    end
  end

  RectCollider = Struct.new(:x, :y, :w, :h) do
    def collides_with?(other)
      send(COLLISION_METHODS[other.class], other)
    end

    def left
      x
    end

    def right
      x + w
    end

    def bottom
      y
    end

    def top
      y + h
    end

    private

    def collides_with_rect?(rect)
      GTK::Geometry.intersect_rect? self, rect, 0
    end

    def collides_with_composite?(composite)
      composite.collides_with? self
    end
  end

  RectCollider::COLLISION_METHODS = {
    RectCollider => :collides_with_rect,
    CompositeCollider => :collides_with_composite?
  }
end
