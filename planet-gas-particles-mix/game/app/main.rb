require 'lib/bubble_sorted_list.rb'
require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/quaternion.rb'
require 'lib/resources.rb'
require 'lib/sprite_resources.rb'

require 'app/resources.rb'

class Array
  def z
    value(2)
  end

  def z=(value)
    self[2] = value
  end
end

class Scrollbar
  attr_reader :value

  def initialize(values = nil)
    initial_values = values || {}
    self.value = initial_values[:value] || 0
    @x = initial_values[:x]
    @y = initial_values[:y]
  end

  def bounds
    [@x, @y, scrollbar_sprite.data[:w], scrollbar_sprite.data[:h]]
  end

  def value=(new_value)
    @value = new_value.clamp(0, 1)
  end

  def tick(args)
    mouse = args.inputs.mouse
    self.value = (mouse.x - min_x) / (max_x - min_x) if mouse.button_left && mouse.inside_rect?(bounds)
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
    ffi_draw.draw_sprite(*bounds, scrollbar_sprite.path)
  end

  def draw_thumb(ffi_draw)
    thumb_x = @x + @value * (max_x - min_x)
    ffi_draw.draw_sprite thumb_x, @y, thumb_sprite.data[:w], thumb_sprite.data[:h], thumb_sprite.path
  end

  def min_x
    @x + thumb_sprite.data[:w].half
  end

  def max_x
    @x + scrollbar_sprite.data[:w] - thumb_sprite.data[:w].half
  end
end

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
    { x: @x, y: @y, w: @corner_size, h: @corner_size, source_x: 0, source_y: 0 }
  end

  def bottom_right
    {
      x: @x + @w - @corner_size, y: @y, w: @corner_size, h: @corner_size,
      source_x: @corner_size + @center_size, source_y: 0
    }
  end

  def top_left
    {
      x: @x, y: @y + @h - @corner_size, w: @corner_size, h: @corner_size,
      source_x: 0, source_y: @corner_size + @center_size
    }
  end

  def top_right
    {
      x: @x + @w - @corner_size, y: @y + @h - @corner_size, w: @corner_size, h: @corner_size,
      source_x: @corner_size + @center_size, source_y: @corner_size + @center_size
    }
  end

  def bottom_side
    {
      x: @x + @corner_size, y: @y, w: @w - 2 * @corner_size, h: @corner_size,
      source_x: @corner_size, source_y: 0, source_w: @center_size
    }
  end

  def left_side
    {
      x: @x, y: @y + @corner_size, w: @corner_size, h: @h - 2 * @corner_size,
      source_x: 0, source_y: @corner_size, source_h: @center_size
    }
  end

  def right_side
    {
      x: @x + @w - @corner_size, y: @y + @corner_size, w: @corner_size, h: @h - 2 * @corner_size,
      source_x: @corner_size + @center_size, source_y: @corner_size, source_h: @center_size
    }
  end

  def top_side
    {
      x: @x + @corner_size, y: @y + @h - @corner_size, w: @w - 2 * @corner_size, h: @corner_size,
      source_x: @corner_size, source_y: @corner_size + @center_size, source_w: @center_size
    }
  end

  def center
    {
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

class Sprite3D < Resources::Sprite
  attr_reader :z

  def z=(value)
    camera_distance = 400
    distance = camera_distance - value
    @z_factor = distance / camera_distance
    @z = value
  end

  def w
    @w * @z_factor
  end

  def h
    @h * @z_factor
  end
end

class Particle < Sprite3D
  def distance_from_center
    Math.sqrt(@x**2 + @y**2 + @z**2)
  end

  def draw_override(ffi_draw)
    alpha = 255 * (@z_factor - 0.4)
    actual_w = w
    actual_h = h
    # x, y, w, h, path
    ffi_draw.draw_sprite_3 @x + 640 - actual_w.half, @y + 360 - actual_h.half, actual_w, actual_h, path,
                           # angle, alpha, red_saturation, green_saturation, blue_saturation
                           nil, alpha, r, g, b,
                           # tile_x, tile_y, tile_w, tile_h
                           nil, nil, nil, nil,
                           # flip_horizontally, flip_vertically,
                           nil, nil,
                           # angle_anchor_x, angle_anchor_y,
                           nil, nil,
                           # source_x, source_y, source_w, source_h
                           nil, nil, nil, nil
  end
end

def particle_at(particle, radius, polar, azimuth)
  sin_polar = Math.sin(polar)

  particle.with(
    x: radius * sin_polar * Math.cos(azimuth),
    y: radius * sin_polar * Math.sin(azimuth),
    z: radius * Math.cos(polar)
  )
end

def randomly_positioned_on_sphere(particle, radius)
  polar = rand * Math::PI
  azimuth = rand * 2 * Math::PI

  particle_at(particle, radius, polar, azimuth)
end

class Rotation
  attr_reader :particle, :v_angle, :axis

  def initialize(particle, values)
    @particle = particle
    @v_angle = values[:v_angle] || 0
    @axis = values[:axis] || [1, 0, 0]
  end

  def v_angle=(value)
    @quaternion = nil
    @v_angle = value
  end

  def axis=(value)
    @quaternion = nil
    @axis = value
  end

  def quaternion
    @quaternion ||= DRT::Quaternion.from_angle_and_axis(@v_angle, @axis.x, @axis.y, @axis.z)
  end

  def tick
    quaternion.apply_to(@particle) unless @v_angle.zero?
  end
end

class ConstantMomentumRotation < Rotation
  attr_reader :radius

  def initialize(particle, values)
    super
    @radius = particle.distance_from_center
  end

  def radius=(value)
    factor = value / @radius
    @particle.x *= factor
    @particle.y *= factor
    @particle.z *= factor
    self.v_angle /= factor**2
  end
end

def random_direction(particle)
  random_axis = [0, 1, 0] # [rand - 0.5, rand - 0.5, rand - 0.5]
  ConstantMomentumRotation.new(particle, v_angle: 0.01, axis: random_axis).tap { |rotation|
    rotation.radius -= rand * 100
  }
end

def setup(args)
  args.state.base_particle ||= Particle.new(Resources.sprites.particle, w: 64, h: 64)
  args.state.particles = 200.times.map { randomly_positioned_on_sphere(args.state.base_particle, 200) }
  args.state.sorted_particles = BubbleSortedList.new(args.state.particles) { |particle| -particle.z }
  args.state.movements = args.state.particles.map { |particle| random_direction(particle) }
  args.state.panel = Panel.new(x: 20, y: 50, w: 200, h: 400)
  args.state.bar = Scrollbar.new(x: 50, y: 100)
end

def render(args)
  args.outputs.background_color = [0, 0, 0]
  args.state.movements.each { |movement|
    movement.tick
    args.state.sorted_particles.fix_sort_order(movement.particle)
  }
  args.outputs.sprites << args.state.sorted_particles
  args.outputs.sprites << args.state.panel
  args.outputs.sprites << args.state.bar
end

def tick(args)
  setup(args) if args.tick_count.zero?

  if args.inputs.keyboard.key_down.up
    args.state.movements.each do |m|
      m.radius += 10
    end
  end
  if args.inputs.keyboard.key_down.down
    args.state.movements.each do |m|
      m.radius -= 10
    end
  end

  args.state.bar.tick(args)

  render(args)
end
