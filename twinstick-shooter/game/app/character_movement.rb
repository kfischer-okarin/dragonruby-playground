require 'app/collisions/collider.rb'

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
    entity.position = entity.position.add_vector entity.movement_direction
  end
end
