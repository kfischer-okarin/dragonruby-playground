require 'lib/debug_mode.rb'
require 'lib/resources.rb'
require 'lib/sprite_resources.rb'

require 'app/resources.rb'

class SphericalCoordinatesSprite < Resources::Sprite
  DEG_360 = 2 * Math::PI

  attr_reader :radius, :polar, :azimuth, :base_w, :base_h, :center_x, :center_y

  def initialize(resource, values = nil)
    super
    @dirty = true
    @base_w ||= w
    @base_h ||= h
    @center_x ||= 0
    @center_y ||= 0
  end

  def x
    @x + @center_x
  end

  def y
    @y + @center_y
  end

  %i[radius base_w base_h].each do |attribute|
    define_method :"#{attribute}=" do |value|
      @dirty = true
      instance_variable_set(:"@#{attribute}", value)
    end
  end

  %i[polar azimuth].each do |attribute|
    define_method :"#{attribute}=" do |value|
      @dirty = true
      instance_variable_set(:"@#{attribute}", value % DEG_360)
    end
  end

  def tick
    return unless @dirty

    z = @radius * Math.cos(@polar)
    z_factor = 0.5 + (@radius - z) / (2 * @radius)
    @w = @base_w * z_factor
    @h = @base_h * z_factor

    sin_polar = Math.sin(@polar)
    @x = @radius * sin_polar * Math.cos(@azimuth) - @w.half
    @y = @radius * sin_polar * Math.sin(@azimuth) - @h.half

    @dirty = false
  end
end

class ConstantSpeedMovement
  attr_accessor :v_polar, :v_azimuth

  def initialize(particle, values)
    @particle = particle
    @v_polar = values[:v_polar] || 0
    @v_azimuth = values[:v_azimuth] || 0
  end

  def tick
    @particle.polar += @v_polar unless @v_polar.zero?
    @particle.azimuth += @v_azimuth unless @v_azimuth.zero?
    @particle.tick
  end
end

def random_particle(args)
  args.state.base_particle.with(polar: rand * Math::PI, azimuth: rand * 2 * Math::PI)
end

def random_direction(particle)
  direction = rand * 2 * Math::PI
  # ConstantSpeedMovement.new(particle, v_polar: Math.sin(direction) * 0.1, v_azimuth: Math.cos(direction) * 0.1)
  ConstantSpeedMovement.new(particle, v_polar: 0.1, v_azimuth: 0.1)
end

def setup(args)
  args.state.base_particle ||= SphericalCoordinatesSprite.new(
    Resources.sprites.particle, center_x: 640, center_y: 360, base_w: 64, base_h: 64, radius: 200
  )
  args.state.particles = 1.times.map { random_particle(args) }
  args.state.movements = args.state.particles.map { |particle| random_direction(particle) }
end

def render(args)
  args.outputs.background_color = [0, 0, 0]
  args.state.movements.each(&:tick)
  args.outputs.sprites << args.state.particles
end



def tick(args)
  setup(args) if args.tick_count.zero?

  render(args)
end
