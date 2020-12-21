class Shooting
  def initialize(bullet_movement)
    @bullet_movement = bullet_movement
    @entities = Set.new
    @weapon_cooldowns = {}
  end

  def register(entity)
    @entities << entity
  end

  def tick
    @entities.each do |entity|
      reduce_cooldowns
      handle_shooting(entity)
    end
  end

  private

  def reduce_cooldowns
    @weapon_cooldowns.keys.each do |entity|
      new_cooldown = @weapon_cooldowns[entity] - 1
      if new_cooldown.zero?
        @weapon_cooldowns.delete(entity)
      else
        @weapon_cooldowns[entity] = new_cooldown
      end
    end
  end

  def handle_shooting(entity)
    spawn_bullet_for(entity) if shooting?(entity) && weapon_ready?(entity)
  end

  def shooting?(entity)
    !entity.fire_direction.zero?
  end

  def weapon_ready?(entity)
    !@weapon_cooldowns.key?(entity)
  end

  def spawn_bullet_for(entity)
    bullet = entity.weapon.create_bullet(entity)
    @bullet_movement.register bullet
    @weapon_cooldowns[entity] = entity.weapon.cooldown
  end
end
