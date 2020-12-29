class BulletMovement
  def initialize(collisions, dynamic_sprites)
    @collisions = collisions
    @dynamic_sprites = dynamic_sprites
    @entities = Set.new
  end

  def register(entity)
    @entities << entity
    @dynamic_sprites.register entity
  end

  def unregister(entity)
    @entities.delete entity
    @dynamic_sprites.unregister entity
  end

  def tick
    @entities.each do |entity|
      handle_movement(entity)
    end
  end

  private

  def handle_movement(entity)
    entity.position = entity.position.add_vector entity.movement_direction.mult_scalar(3)
    unregister(entity) unless entity.position.inside_rect?([-20, -20, 360, 220])
  end
end
