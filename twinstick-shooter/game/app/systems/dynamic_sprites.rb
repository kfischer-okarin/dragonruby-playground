class DynamicSprites
  def initialize
    @entities = Set.new
    @sprites_by_entity = {}
  end

  def register(entity)
    @entities << entity
    @sprites_by_entity[entity] = entity.sprite
  end

  def unregister(entity)
    @entities.delete entity
    @sprites_by_entity.delete entity
  end

  def sprites
    @sprites_by_entity.values
  end

  def tick
    sprites.each(&:tick)
  end
end
