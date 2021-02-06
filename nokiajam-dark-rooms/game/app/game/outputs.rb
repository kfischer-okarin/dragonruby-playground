require 'lib/low_resolution_canvas.rb'

class Game
  # Specialized Outputs for Nokia Jam
  class Outputs
    SCREEN_W = 84
    SCREEN_H = 48

    def initialize
      @canvas = DRT::LowResolutionCanvas.new([SCREEN_W, SCREEN_H])
      @sprites = {}
      @sprites_to_construct = []
    end

    def sprite(path)
      @sprites[path]
    end

    def register_sprite(sprite)
      @sprites[sprite.path] = sprite.sprite
    end

    def queue_sprite_construction(id, pixels)
      @sprites_to_construct << { id: id, pixels: pixels }
    end

    def render(primitive, &transform)
      @canvas.primitives << transform_primitive(primitive, transform)
    end

    def process(args)
      initialize_sprites(args) unless @sprites_to_construct.empty?
      args.outputs.background_color = Primitive::BLACK_ARRAY
      @canvas.background_color = Primitive::BLACK_ARRAY
      args.outputs.primitives << @canvas
    end

    private

    def transform_primitive(primitive, transform)
      return primitive unless transform

      if primitive.primitive_marker
        transform.call(primitive)
      else
        primitive.map { |single_primitive| transform.call(single_primitive) }
      end
    end

    def initialize_sprites(args)
      @sprites_to_construct.each do |created_sprite|
        SpriteBuilder.new(args, created_sprite[:id]).build(created_sprite[:pixels])
      end
      @sprites_to_construct.clear
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
