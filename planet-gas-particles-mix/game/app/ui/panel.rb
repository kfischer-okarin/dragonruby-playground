module UI
  # UI Panel
  class Panel
    attr_accessor :x, :y, :w, :h

    def initialize(values)
      @path = Resources.sprites.panel.path
      @corner_size = 36
      @center_size = 56
      @x = values[:x]
      @y = values[:y]
      @w = values[:w]
      @h = values[:h]
    end

    def primitive_marker
      :sprite
    end

    def draw_override(ffi_draw)
      [
        bottom_left, bottom_right, top_left, top_right,
        bottom_side, left_side, right_side, top_side,
        center
      ].each { |part|
        draw_part(ffi_draw, part)
      }
    end

    private

    def bottom_left
      @bottom_left ||= { x: @x, y: @y, w: @corner_size, h: @corner_size, source_x: 0, source_y: 0 }
    end

    def bottom_right
      @bottom_right ||= {
        x: @x + @w - @corner_size, y: @y, w: @corner_size, h: @corner_size,
        source_x: @corner_size + @center_size, source_y: 0
      }
    end

    def top_left
      @top_left ||= {
        x: @x, y: @y + @h - @corner_size, w: @corner_size, h: @corner_size,
        source_x: 0, source_y: @corner_size + @center_size
      }
    end

    def top_right
      @top_right ||= {
        x: @x + @w - @corner_size, y: @y + @h - @corner_size, w: @corner_size, h: @corner_size,
        source_x: @corner_size + @center_size, source_y: @corner_size + @center_size
      }
    end

    def bottom_side
      @bottom_side ||= {
        x: @x + @corner_size, y: @y, w: @w - 2 * @corner_size, h: @corner_size,
        source_x: @corner_size, source_y: 0, source_w: @center_size
      }
    end

    def left_side
      @left_side ||= {
        x: @x, y: @y + @corner_size, w: @corner_size, h: @h - 2 * @corner_size,
        source_x: 0, source_y: @corner_size, source_h: @center_size
      }
    end

    def right_side
      @right_side ||= {
        x: @x + @w - @corner_size, y: @y + @corner_size, w: @corner_size, h: @h - 2 * @corner_size,
        source_x: @corner_size + @center_size, source_y: @corner_size, source_h: @center_size
      }
    end

    def top_side
      @top_side ||= {
        x: @x + @corner_size, y: @y + @h - @corner_size, w: @w - 2 * @corner_size, h: @corner_size,
        source_x: @corner_size, source_y: @corner_size + @center_size, source_w: @center_size
      }
    end

    def center
      @center ||= {
        x: @x + @corner_size, y: @y + @corner_size, w: @w - 2 * @corner_size, h: @h - 2 * @corner_size,
        source_x: @corner_size, source_y: @corner_size, source_w: @center_size, source_h: @center_size
      }
    end

    def draw_part(ffi_draw, part)
      ffi_draw.draw_sprite_3 part.x, part.y, part.w, part.h, @path,
                            # angle, alpha, red_saturation, green_saturation, blue_saturation
                            nil, nil, nil, nil, nil,
                            # tile_x, tile_y, tile_w, tile_h
                            nil, nil, nil, nil,
                            # flip_horizontally, flip_vertically,
                            nil, nil,
                            # angle_anchor_x, angle_anchor_y,
                            nil, nil,
                            # source_x, source_y, source_w, source_h
                            part.source_x, part.source_y, part.source_w || part.w, part.source_h || part.h
    end
  end
end
