module Sprites
  SPRITES = {
    wall_with_door_dark: ['XX X X X X X           X X X X X XX'],
    wall_dark: ['XX X X X X X X X X X X X X X X X XX'],
    light_beam: [
      '     X   X     ',
      '      XXX      ',
      '  X XXXXXXX X  ',
      '   XX XXX XX   ',
      'X XX XXXXX XX X',
      ' X XXXXXXXXX X ',
      '  XXXXXXXXXXX  '
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
