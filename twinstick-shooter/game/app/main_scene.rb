require 'app/collisions.rb'
require 'app/bullet_movement.rb'
require 'app/character_movement.rb'
require 'app/character_orientation.rb'
require 'app/dynamic_sprites.rb'
require 'app/shooting.rb'

require 'app/entity.rb'
require 'app/player_sprite.rb'
require 'app/sonic_gun.rb'

class MainScene
  attr_reader :next_scene

  def initialize
    @dynamic_sprites = DynamicSprites.new
    @collisions = Collisions.new
    @character_orientation = CharacterOrientation.new
    @character_movement = CharacterMovement.new(@collisions)
    @bullet_movement = BulletMovement.new(@collisions, @dynamic_sprites)
    @shooting = Shooting.new(@bullet_movement)
    @player = Entity.new(
      position: [160, 90],
      movement_direction: [0, 0],
      fire_direction: [0, 0],
      orientation: [0, -1],
      sprite: ->(player) { PlayerSprite.new(player) },
      collider: ->(player) { Collisions::RectCollider.new(player.position.x - 5, player.position.y, 10, 6) },
      weapon: SonicGun.new(cooldown: 20)
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
    @dynamic_sprites.register @player
    @collisions.register @stage
    @character_orientation.register @player
    @character_movement.register @player
    @shooting.register @player
  end

  def tick(game_inputs)
    process_inputs(game_inputs)
    system_ticks
  end

  def render(game_outputs)
    game_outputs.draw background
    game_outputs.draw @dynamic_sprites.sprites
    return unless $args.debug.active?
    game_outputs.draw [@player.collider.x, @player.collider.y, @player.collider.w, @player.collider.h, 255, 0, 0].border
    game_outputs.draw [@player.position.x, @player.position.y, 1, 1, 0, 0, 255].solid
  end

  private

  def process_inputs(game_inputs)
    @player.movement_direction = game_inputs.direction
    @player.fire_direction = game_inputs.fire_direction
  end

  def system_ticks
    @character_orientation.tick
    @character_movement.tick
    @bullet_movement.tick
    @shooting.tick
    @dynamic_sprites.tick
  end

  def background
    @background ||= Primitives::Sprite.new(Resources.sprites.background, r: 97, g: 162, b: 255)
  end
end
