require 'lib/debug_mode.rb'
require 'lib/resources.rb'
require 'lib/sprite_resources.rb'

require 'app/resources.rb'

class SpriteWithSphericalCoordinates < Resources::Sprite
  attr_reader :radius, :polar, :azimuth, :base_w, :base_h, :center_x, :center_y

  def initialize(resource, values = nil)
    super
    @dirty = true
    @base_w ||= w
    @base_h ||= h
    @center_x ||= 0
    @center_y ||= 0
  end

  %i[radius polar azimuth base_w base_h].each do |method|
    define_method :"#{method}=" do |value|
      instance_variable_set(:"@#{method}", value)
      @dirty = true
    end
  end

  def x
    @x + @center_x
  end

  def y
    @y + @center_y
  end

  def w
    @base_w * @z_factor
  end

  def h
    @base_h * @z_factor
  end

  def tick
    return unless @dirty

    sin_polar = Math.sin(@polar)
    @x = @radius * sin_polar * Math.cos(@azimuth)
    @y = @radius * sin_polar * Math.sin(@azimuth)
    z = @radius * Math.cos(@polar)
    @z_factor = 0.5 + (@radius - z) / (2 * @radius)
    @dirty = false
  end
end

def setup(args)
  args.state.base_particle ||= SpriteWithSphericalCoordinates.new(
    Resources.sprites.particle, center_x: 640, center_y: 360, base_w: 64, base_h: 64, radius: 200
  )
  args.state.particles = 100.times.map { random_particle(args) }
end

def render(args)
  args.outputs.background_color = [0, 0, 0]
  args.state.particles.each(&:tick)
  args.outputs.sprites << args.state.particles
end

def random_particle(args)
  args.state.base_particle.with(polar: rand * Math::PI, azimuth: rand * 2 * Math::PI)
end

def tick(args)
  setup(args) if args.tick_count.zero?

  render(args)
end
