require 'app/collisions.rb'
require 'app/entity.rb'

class MainScene
  attr_reader :next_scene

  def initialize
    @collisions = Collisions.new
    @movement_direction = [0, 0]
    @position = [160, 90]
    @stage = Entity.new(
      collider: Collisions::CompositeCollider.new([
        Collisions::RectCollider.new(0, 0, 320, 20),
        Collisions::RectCollider.new(0, 164, 320, 16),
        Collisions::RectCollider.new(0, 20, 24, 144),
        Collisions::RectCollider.new(296, 20, 24, 144)
      ]),
      wall: true
    )
    @collisions.register @stage
  end

  def tick(game_inputs)
    @movement_direction = game_inputs.direction
    @position = @position.add_vector @movement_direction
  end

  def render(game_outputs)
    game_outputs.draw background
    game_outputs.draw [@position.x, @position.y, 10, 16, 255, 0, 0].solid
  end

  private

  def background
    @background ||= Primitives::Sprite.new(Resources.sprites.background)
  end
end
