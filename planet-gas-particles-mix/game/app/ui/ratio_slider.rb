module UI
  # Slider that can set a ratio
  class RatioSlider
    # Slider thumb
    class Thumb
      attr_reader :value, :w

      def initialize(slider, value)
        @slider = slider
        self.value = value
        @path = Resources.sprites.scrollbar_thumb.path
        @w = Resources.sprites.scrollbar_thumb.data[:w]
        @h = Resources.sprites.scrollbar_thumb.data[:h]
      end

      def value=(new_value)
        @value = new_value.clamp(0, 1)
      end

      def dragging?
        @dragging
      end

      def tick(args)
        mouse = args.inputs.mouse
        @dragging = false unless mouse.button_left
        return unless mouse.button_left && (mouse.inside_rect?(bounds) || @dragging)

        self.value = @slider.value_of_x(mouse.x - @w.half)
        @dragging = true
      end

      def x
        @slider.x_for_value(@value)
      end

      def y
        @slider.y
      end

      def draw(ffi_draw)
        ffi_draw.draw_sprite x, y, @w, @h, @path
      end

      private

      def bounds
        [x, y, @w, @h]
      end
    end

    # Background
    class Background
      attr_reader :h

      def initialize(slider, colors)
        @slider = slider
        @path = Resources.sprites.scrollbar.path
        @h = Resources.sprites.scrollbar.data[:h]
        @end_size = 16
        @colors = colors
      end

      def x
        @slider.x
      end

      def y
        @slider.y
      end

      def w
        @slider.w
      end

      def draw(ffi_draw)
        draw_part(ffi_draw, left_part)
        middle_parts.each do |part|
          draw_part(ffi_draw, part)
        end
        draw_part(ffi_draw, right_part)
      end

      private

      def left_part
        { x: x, y: y, w: @end_size, h: @h, source_x: 0, source_y: 0 }.merge(@colors[0])
      end

      def middle_parts
        values = [0, *@slider.thumb_values, 1]
        x_coords = values.map { |value| @slider.x_for_value(value) }
        (0...(values.length - 1)).map { |index|
          middle_part(x_coords[index] + @end_size, x_coords[index + 1] + 2 * @end_size).merge(@colors[index])
        }
      end

      def middle_part(start_x, end_x)
        { x: start_x, y: y, w: end_x - start_x, h: @h, source_x: 16, source_y: 0, source_w: 128 - 2 * @end_size }
      end

      def right_part
        { x: x + w - @end_size, y: y, w: @end_size, h: @h, source_x: 128 - @end_size, source_y: 0 }.merge(@colors[-1])
      end

      def draw_part(ffi_draw, part)
        ffi_draw.draw_sprite_3 part.x, part.y, part.w, part.h, @path,
                               # angle, alpha, red_saturation, green_saturation, blue_saturation
                               nil, 192, part.r, part.g, part.b,
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

    attr_accessor :x, :y, :w
    attr_reader :h, :input_handlers

    def initialize(values = nil)
      initial_values = values || {}
      @background = Background.new(self, initial_values[:colors])
      @thumbs = [Thumb.new(self, 0.33), Thumb.new(self, 0.66)]
      @x = initial_values[:x]
      @y = initial_values[:y]
      @w = initial_values[:w] || Resources.sprites.scrollbar.data[:w]
      @h = @background.h
      @input_handlers = []
    end

    def thumb_values
      @thumbs.map(&:value)
    end

    def bounds
      [@x, @y, @w, @h]
    end

    def tick(args)
      if dragged_thumb
        continue_drag(args)
      else
        check_for_drag(args)
      end
    end

    def primitive_marker
      :sprite
    end

    def draw_override(ffi_draw)
      @background.draw(ffi_draw)
      draw_thumbs(ffi_draw)
    end

    def x_for_value(value)
      min_x + value * (max_x - min_x)
    end

    def value_of_x(x) # rubocop:disable Naming/MethodParameterName
      (x - min_x) / (max_x - min_x)
    end

    private

    def dragged_thumb
      return nil unless @dragged_thumb_index

      @thumbs[@dragged_thumb_index]
    end

    def check_for_drag(args)
      @thumbs.each_with_index do |thumb, index|
        thumb.tick(args)
        if thumb.dragging?
          @dragged_thumb_index = index
          break
        end
      end
    end

    def continue_drag(args)
      dragged_thumb.tick(args)
      adjust_left_thumbs
      adjust_right_thumbs
      notify_input_handlers
      @dragged_thumb_index = nil unless dragged_thumb.dragging?
    end

    def adjust_left_thumbs
      return if @dragged_thumb_index.zero?

      left_thumbs = @thumbs[0..(@dragged_thumb_index - 1)]
      left_thumbs.each do |thumb|
        thumb.value = dragged_thumb.value if thumb.value > dragged_thumb.value
      end
    end

    def adjust_right_thumbs
      return if @dragged_thumb_index == @thumbs.length - 1

      right_thumbs = @thumbs[(@dragged_thumb_index + 1)..-1]
      right_thumbs.each do |thumb|
        thumb.value = dragged_thumb.value if thumb.value < dragged_thumb.value
      end
    end

    def notify_input_handlers
      @input_handlers.each do |handler|
        handler.call(thumb_values)
      end
    end

    def min_x
      @min_x ||= @x
    end

    def max_x
      @max_x ||= @x + @w - @thumbs[0].w
    end

    def draw_thumbs(ffi_draw)
      @thumbs.each do |thumb|
        thumb.draw(ffi_draw)
      end
      dragged_thumb&.draw(ffi_draw) # Draw dragged thumb always on top
    end
  end
end
