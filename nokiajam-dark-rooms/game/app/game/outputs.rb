require 'lib/low_resolution_canvas.rb'

class Game
  # Specialized Outputs for Nokia Jam
  class Outputs
    def self.color_as_int(color)
      color[2] + color[1] * 0x100 + color[0] * 0x10000 + 0xFF000000
    end

    def w
      84
    end

    def h
      48
    end

    BLACK = [67, 82, 61].freeze
    WHITE = [199, 240, 216].freeze

    BLACK_INT = color_as_int(BLACK)
    WHITE_INT = color_as_int(WHITE)

    def initialize
      @canvas = DRT::LowResolutionCanvas.new([w, h])
      @sprites = {}
      @created_sprites = []
    end

    # pixels example:
    # [
    #   "  XXXX  ",
    #   " X    X ",
    #   "X      X",
    #   "XXXXXXXX"
    # ]
    def create_sprite(id, pixels)
      @sprites[id] = { w: pixels[0].size, h: pixels.size }
      @created_sprites << { id: id, pixels: pixels }
    end

    def render_sprite(x, y, id, options = nil)
      @canvas.primitives << { x: x, y: y, path: id, **@sprites[id], **(options || {}) }.sprite
    end

    def process(args)
      initialize_sprites(args) unless @created_sprites.empty?
      args.outputs.background_color = BLACK
      @canvas.background_color = BLACK
      args.outputs.primitives << @canvas
    end

    private

    def initialize_sprites(args)
      @created_sprites.each do |created_sprite|
        SpriteBuilder.new(args, created_sprite[:id]).build(created_sprite[:pixels])
      end
      @created_sprites.clear
    end

    # Build a sprite from a array of strings representing a lowrez 1 color sprite
    class SpriteBuilder
      def self.dimensions(pixels)
        [pixels[0].size, pixels.size]
      end

      def initialize(args, id)
        @pixel_array = args.pixel_array(id)
      end

      def build(pixels)
        @pixel_array.width, @pixel_array.height = SpriteBuilder.dimensions(pixels)
        @pixel_array.pixels.fill(0x00000000, 0, @pixel_array.width * @pixel_array.height)
        fill_with pixels
      end

      private

      def fill_with(pixels)
        w = @pixel_array.width

        pixels.each_with_index do |row, y|
          row.chars.each_with_index do |pixel, x|
            @pixel_array.pixels.fill(WHITE_INT, y * w + x, 1) unless pixel == ' '
          end
        end
      end
    end
  end
end
