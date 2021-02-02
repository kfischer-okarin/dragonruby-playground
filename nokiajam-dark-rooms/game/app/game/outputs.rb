require 'lib/low_resolution_canvas.rb'

class Game
  # Specialized Outputs for Nokia Jam
  class Outputs
    W = 84
    H = 48

    BG_COLOR = [199, 240, 216].freeze
    FG_COLOR = [67, 82, 61].freeze

    def initialize
      @canvas = DRT::LowResolutionCanvas.new([W, H])
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

    def render_sprite(x, y, id)
      @canvas.primitives << { x: x, y: y, path: id }.merge(@sprites[id]).sprite
    end

    def process(args)
      initialize_sprites(args) unless @created_sprites.empty?
      args.outputs.background_color = BG_COLOR
      @canvas.background_color = BG_COLOR
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
            @pixel_array.pixels.fill(0xFF43523D, y * w + x, 1) unless pixel == ' '
          end
        end
      end
    end
  end
end
