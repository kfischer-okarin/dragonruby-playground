module Sprites
  WALL_LENGTH = 29
  DOOR_SIZE = 9
  HALF_WALL_LENGTH = (WALL_LENGTH - DOOR_SIZE).idiv 2

  SPRITES = {
    wall_with_door: ['X' * HALF_WALL_LENGTH + ' ' * DOOR_SIZE + 'X' * HALF_WALL_LENGTH],
    wall: ['X' * WALL_LENGTH],
    wall_with_door_dark: ['XX X X X X         X X X X XX'],
    wall_dark: ['XX X X X X X X X X X X X X XX'],
    light_beam: [
      '     X   X     ',
      '       X       ',
      '  X XXXXXXX X  ',
      '   XXX X XXX   ',
      'X XX XXXXX XX X',
      ' XXXXXXXXXXXXX ',
      ' X XXXXXXXXX X ',
      '  XXXXXXXXXXX  ',
      '  XXXXXXXXXXX  ',
      '   XXXXXXXXX   '
    ]
  }.freeze

  class << self
    def prepare
      SPRITES.each do |name, pixels|
        build(name, pixels)
      end
    end

    # pixels example:
    # [
    #   "  XXXX  ",
    #   " X    X ",
    #   "X      X",
    #   "XXXXXXXX"
    # ]
    def build(id, pixels)
      register(path: id, w: pixels[0].size, h: pixels.size)
      $outputs.queue_sprite_construction(id, pixels)
    end

    def register(sprite)
      $outputs.register_sprite(sprite)
    end
  end
end
