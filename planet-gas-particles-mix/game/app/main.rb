require 'lib/bubble_sorted_list.rb'
require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/quaternion.rb'
require 'lib/resources.rb'
require 'lib/sprite_resources.rb'

require 'app/resources.rb'
require 'app/ui/layout.rb'
require 'app/ui/panel.rb'
require 'app/ui/ratio_slider.rb'

class Array
  def z
    value(2)
  end

  def z=(value)
    self[2] = value
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

class GasCompositionSetting < UI::Panel
  def initialize
    super(x: 30, y: 30, w: 1220, h: 100)
    @layout = UI::Layout.new(self, padding_vertical: 32, padding_horizontal: 20)
    @colors = [
      { r: 228, g: 59, b: 68 },
      { r: 62, g: 137, b: 72 },
      { r: 0, g: 149, b: 233 }
    ]
    @ratios = UI::RatioSlider.new(colors: @colors)
    build_layout
  end

  private

  def build_layout
    @layout << @ratios
    self << @layout
  end
end

def setup(args)
  args.state.base_particle ||= Particle.new(Resources.sprites.particle, w: 64, h: 64)
  args.state.particles = 200.times.map { randomly_positioned_on_sphere(args.state.base_particle, 200) }
  args.state.sorted_particles = BubbleSortedList.new(args.state.particles) { |particle| -particle.z }
  args.state.movements = args.state.particles.map { |particle| random_direction(particle) }
  args.state.panel = GasCompositionSetting.new
end

def render(args)
  args.outputs.background_color = [0, 0, 0]
  args.state.movements.each { |movement|
    movement.tick
    args.state.sorted_particles.fix_sort_order(movement.particle)
  }
  args.outputs.sprites << args.state.sorted_particles
  args.outputs.sprites << args.state.panel
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

  args.state.panel.tick(args)

  render(args)
end
