module UI
  # Scrollbar that represents a value between 0 and 1
  class Scrollbar
    attr_accessor :x, :y, :w
    attr_reader :h, :value, :on_input_handlers

    def initialize(values = nil)
      initial_values = values || {}
      self.value = initial_values[:value] || 0
      @x = initial_values[:x]
      @y = initial_values[:y]
      @w = initial_values[:w] || scrollbar_sprite.data[:w]
      @h = scrollbar_sprite.data[:h]
      @path = scrollbar_sprite.path
      @end_size = 16
      @on_input_handlers = []
    end

    def bounds
      [@x, @y, @w, @h]
    end

    def value=(new_value)
      @value = new_value.clamp(0, 1)
    end

    def tick(args)
      mouse = args.inputs.mouse
      return unless mouse.button_left && mouse.inside_rect?(bounds)

      self.value = (mouse.x - min_x) / (max_x - min_x)

      @on_input_handlers.each do |handler|
        handler.call(@value)
      end
    end

    def primitive_marker
      :sprite
    end

    def draw_override(ffi_draw)
      draw_background(ffi_draw)
      draw_thumb(ffi_draw)
    end

    private

    def scrollbar_sprite
      Resources.sprites.scrollbar
    end

    def thumb_sprite
      Resources.sprites.scrollbar_thumb
    end

    def draw_background(ffi_draw)
      [scrollbar_left, scrollbar_middle, scrollbar_right].each do |part|
        draw_scrollbar_part(ffi_draw, part)
      end
    end

    def scrollbar_left
      { x: @x, y: @y, w: @end_size, h: @h, source_x: 0, source_y: 0 }
    end

    def scrollbar_middle
      { x: @x + @end_size, y: @y, w: @w - 2 * @end_size, h: @h, source_x: 16, source_y: 0, source_w: 128 - 2 * @end_size }
    end

    def scrollbar_right
      { x: @x + @w - @end_size, y: @y, w: @end_size, h: @h, source_x: 128 - @end_size, source_y: 0 }
    end

    def draw_scrollbar_part(ffi_draw, part)
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

    def draw_thumb(ffi_draw)
      thumb_x = @x + @value * (max_x - min_x)
      ffi_draw.draw_sprite thumb_x, @y, thumb_sprite.data[:w], thumb_sprite.data[:h], thumb_sprite.path
    end

    def min_x
      @x + thumb_sprite.data[:w].half
    end

    def max_x
      @x + @w - thumb_sprite.data[:w].half
    end
  end
end
