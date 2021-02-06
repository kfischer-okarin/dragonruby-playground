module Primitive
  class << self
    def color_as_int(color)
      color[:b] + color[:g] * 0x100 + color[:r] * 0x10000 + 0xFF000000
    end

    def color_as_array(color)
      [color[:r], color[:g], color[:b]]
    end

    def color(values)
      case values[:color]
      when :black
        BLACK
      when :white
        WHITE
      else
        {}
      end
    end

    def sprite(id, values)
      $outputs.sprite(id).merge(color(values)).merge(values)
    end

    def rect(values)
      values.merge(color(values)).solid
    end
  end

  BLACK = { r: 67, g: 82, b: 61 }.freeze
  WHITE = { r: 199, g: 240, b: 216 }.freeze

  BLACK_ARRAY = color_as_array(BLACK)
  WHITE_ARRAY = color_as_array(WHITE)

  BLACK_INT = color_as_int(BLACK)
  WHITE_INT = color_as_int(WHITE)
end
