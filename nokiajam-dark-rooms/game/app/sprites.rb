module Sprites
  WALL_LENGTH = 29
  DOOR_SIZE = 9
  HALF_WALL_LENGTH = (WALL_LENGTH - DOOR_SIZE).idiv 2

  SPRITES = {
    wall_with_door: ['X' * HALF_WALL_LENGTH + ' ' * DOOR_SIZE + 'X' * HALF_WALL_LENGTH],
    wall: ['X' * WALL_LENGTH],
    wall_with_door_dark: ['XX X X X X         X X X X XX'],
    wall_dark: ['XX X X X X X X X X X X X X XX']
  }.freeze

  def self.prepare
    SPRITES.each do |name, pixels|
      $outputs.create_sprite(name, pixels)
    end
  end
end
