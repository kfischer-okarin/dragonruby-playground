require 'lib/debug_mode.rb'
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

def randomly_positioned_on_sphere(particle, radius)
  polar = rand * Math::PI
  azimuth = rand * 2 * Math::PI

  sin_polar = Math.sin(polar)

  particle.with(
    x: radius * sin_polar * Math.cos(azimuth),
    y: radius * sin_polar * Math.sin(azimuth),
    z: radius * Math.cos(polar),
    r: rand * 255,
    g: rand * 255,
    b: rand * 255
  )
end

class Rotation
  attr_reader :v_angle, :axis

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
  args.state.particles = 100.times.map { randomly_positioned_on_sphere(args.state.base_particle, 200) }
  args.state.movements = args.state.particles.map { |particle| random_direction(particle) }
end

def render(args)
  args.outputs.background_color = [0, 0, 0]
  args.state.movements.each(&:tick)
  args.outputs.sprites << args.state.particles
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

  render(args)
end
