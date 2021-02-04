module Sprites
  WALL_LENGTH = 30
  DOOR_SIZE = 8

  SPRITES = {
    wall_with_door: ['X' * (WALL_LENGTH - DOOR_SIZE).half + ' ' * DOOR_SIZE + 'X' * (WALL_LENGTH - DOOR_SIZE).half],
    wall: ['X' * WALL_LENGTH]
  }.freeze

  def self.prepare
    SPRITES.each do |name, pixels|
      $outputs.create_sprite(name, pixels)
    end
  end
end
