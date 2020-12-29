class CharacterMovement
  def initialize(collisions)
    @collisions = collisions
    @entities = Set.new
  end

  def register(entity)
    @entities << entity
  end

  def tick
    @entities.each do |entity|
      handle_movement(entity)
    end
  end

  private

  def handle_movement(entity)
    entity.position = entity.position.add_vector movement_direction_after_collision(entity)
  end

  def movement_direction_after_collision(entity)
    possible_movement_directions(entity).find { |movement_direction|
      !@collisions.collides_with?(entity.collider.offset_by(movement_direction), :wall)
    } || [0, 0]
  end

  def possible_movement_directions(entity)
    [entity.movement_direction].tap { |result|
      if entity.movement_direction.diagonal?
        result << [entity.movement_direction.x, 0]
        result << [0, entity.movement_direction.y]
      end
    }
  end
end
