module UI
  # Arranges UI elements vertically in parent
  class VerticalLayout
    def initialize(parent, values = nil)
      @parent = parent
      @parent_values = {}
      @padding = { top: 20, bottom: 20, left: 20, right: 20 }
      @child_padding = 20
      @children = []
      return unless values

      values.each do |attribute, value|
        send("#{attribute}=", value)
      end
    end

    def padding=(value)
      self.padding_vertical = value
      self.padding_horizontal = value
    end

    def padding_vertical=(value)
      self.padding_top = value
      self.padding_bottom = value
    end

    def padding_horizontal=(value)
      self.padding_left = value
      self.padding_right = value
    end

    %i[top bottom left right].each do |direction|
      define_method :"padding_#{direction}=" do |value|
        @padding[direction] = value
      end
    end

    def <<(child)
      @children << child
    end

    def tick(args)
      check_parent_dimensions
      update_child_dimensions if @dirty
      @children.each do |child|
        child.tick(args)
      end
    end

    def primitive_marker
      :sprite
    end

    def draw_override(ffi_draw)
      @children.each do |child|
        child.draw_override(ffi_draw)
      end
    end

    private

    def check_parent_dimensions
      %i[x y w h].each do |attribute|
        if @parent_values[attribute] != @parent.send(attribute)
          @parent_values[attribute] = @parent.send(attribute)
          @dirty = true
        end
      end
    end

    def update_child_dimensions
      child_dimensions = first_child_dimensions

      @children.each do |child|
        child_dimensions.y -= child.h
        child.x = child_dimensions.x
        child.y = child_dimensions.y
        child.w = child_dimensions.w
        child_dimensions.y -= @child_padding
      end
      @dirty = false
    end

    def first_child_dimensions
      [
        @parent_values[:x] + @padding[:left], # x
        @parent_values[:y] + @parent_values[:h] - @padding[:top], # y
        @parent_values[:w] - @padding[:left] - @padding[:right] # w
      ]
    end
  end
end
