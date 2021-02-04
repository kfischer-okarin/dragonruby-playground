require 'lib/low_resolution_canvas.rb'

class Game
  # Specialized Outputs for Nokia Jam
  class Outputs
    def self.color_as_int(color)
      color[:b] + color[:g] * 0x100 + color[:r] * 0x10000 + 0xFF000000
    end

    def self.color_as_array(color)
      [color[:r], color[:g], color[:b]]
    end

    def w
      84
    end

    def h
      48
    end

    BLACK = { r: 67, g: 82, b: 61 }.freeze
    WHITE = { r: 199, g: 240, b: 216 }.freeze

    BLACK_ARRAY = color_as_array(BLACK)
    WHITE_ARRAY = color_as_array(WHITE)

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

    def render_sprite(x, y, id, opts = nil)
      options = opts || {}
      primitive = { x: x, y: y, path: id, **@sprites[id], **color(options), **options }.sprite
      @canvas.primitives << primitive
    end

    def render_rect(x, y, w, h, opts = nil)
      options = opts || {}
      primitive = { x: x, y: y, w: w, h: h, **color(options), **options }.solid
      @canvas.primitives << primitive
    end

    def process(args)
      initialize_sprites(args) unless @created_sprites.empty?
      args.outputs.background_color = BLACK_ARRAY
      @canvas.background_color = BLACK_ARRAY
      args.outputs.primitives << @canvas
    end

    private

    def color(options)
      options[:invert] ? BLACK : WHITE
    end

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
            @pixel_array.pixels.fill(0xFFFFFFFF, y * w + x, 1) unless pixel == ' '
          end
        end
      end
    end
  end
end
