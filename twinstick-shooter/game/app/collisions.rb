require 'app/collisions/collider.rb'

class Collisions
  def initialize
    @entities = {}
  end

  def register(entity)
    entity.component_types.each do |type|
      next if type == :collider
      @entities[type] ||= Set.new
      @entities[type] << entity
    end
  end

  def collides_with?(collider, component_type)
    return false unless @entities.key? component_type

    @entities[component_type].any? { |entity|
      collider.collides_with?(entity.collider)
    }
  end
end
