require 'app/collisions.rb'
require 'app/character_movement.rb'
require 'app/entity.rb'

class MainScene
  attr_reader :next_scene

  def initialize
    @collisions = Collisions.new
    @character_movement = CharacterMovement.new(@collisions)
    @player = Entity.new(
      position: [160, 90],
      movement_direction: [0, 0],
      collider: ->(player) { Collisions::RectCollider.new(player.position.x, player.position.y, 10, 10) }
    )
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
    @character_movement.register @player
  end

  def tick(game_inputs)
    @player.movement_direction = game_inputs.direction
    @character_movement.tick
  end

  def render(game_outputs)
    game_outputs.draw background
    game_outputs.draw [@player.position.x, @player.position.y, 10, 16, 255, 0, 0].solid
  end

  private

  def background
    @background ||= Primitives::Sprite.new(Resources.sprites.background)
  end
end
