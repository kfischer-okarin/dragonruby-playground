require 'lib/synthesizer.rb'

class SonicGun
  class Sprite < Primitives::Sprite
    def initialize(bullet)
      super(Resources.sprites.sonic_gun_bullet, w: 16, h: 16, source_w: 16, source_h: 16)
      @bullet = bullet
      vertical = bullet.movement_direction.x.zero?
      @source_x = vertical ? 0 : 16
      @source_y = 0
      @flip_horizontally = !vertical && bullet.movement_direction.x.negative?
      @flip_vertically = vertical && bullet.movement_direction.y.negative?
      @r, @g, @b = [0, 255, 0]
    end

    def tick
      @x = @bullet.position.x - 8
      @y = @bullet.position.y - 8
    end
  end

  attr_reader :cooldown, :frequency

  def initialize(values)
    @cooldown = values[:cooldown]
    @frequency = values[:frequency]
  end

  OFFSET = {
    [0, 1] => [1, 10],
    [1, 0] => [6, 4],
    [0, -1] => [-2, 2],
    [-1, 0] => [-7, 4]
  }.freeze

  def create_bullet(entity)
    Entity.new(
      position: entity.position.add_vector(OFFSET[entity.orientation]),
      movement_direction: entity.orientation.dup,
      sprite: ->(bullet) { Sprite.new(bullet) },
      sound: self.class.bullet_sound_for(@frequency)
    )
  end

  def frequency=(value)
    @frequency = value.clamp(min_frequency, max_frequency)
  end

  def max_frequency
    1000
  end

  def min_frequency
    100
  end

  SAMPLE_RATE = 48_000

  def self.bullet_sound_for(frequency)
    @bullet_sound_for ||= {}
    @bullet_sound_for[frequency] ||= generate_bullet_sound(frequency)
  end

  def self.generate_bullet_sound(base_frequency)
    length = 1 * (100 / base_frequency)**(1 / 3)
    Synthesizer.new(SAMPLE_RATE)
               .sine_wave(base_frequency)
               .modulate(:frequency, { frequency: 0.5 / length, amplitude: 1, phase_shift: Math::PI * 0.5 })
               .envelope_adsr(length * 0.1, length * 0.2, 0.8, length * 0.1)
               .normalize(0.05)
               .generate(length)
  end

  $args.debug.on_reset do
    instance_variable_set('@bullet_sound', nil)
  end
end
