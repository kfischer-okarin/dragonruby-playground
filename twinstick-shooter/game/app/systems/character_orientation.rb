class CharacterOrientation
  def initialize
    @entities = Set.new
  end

  def register(entity)
    @entities << entity
  end

  def tick
    @entities.each do |entity|
      update_orientation(entity)
    end
  end

  private

  def update_orientation(entity)
    return unless orientation_changed?(entity)

    direction = effective_direction(entity)

    entity.orientation = direction.y.zero? ? [direction.x, 0] : [0, direction.y]
  end

  def orientation_changed?(entity)
    direction = effective_direction(entity)
    return false if direction.zero?

    if entity.orientation.x.zero?
      direction.y != entity.orientation.y
    else
      direction.x != entity.orientation.x
    end
  end

  def effective_direction(entity)
    if entity.fire_direction.zero?
      entity.movement_direction
    else
      entity.fire_direction
    end
  end
end
