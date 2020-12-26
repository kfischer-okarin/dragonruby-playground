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

  attr_reader :cooldown

  def initialize(values)
    @cooldown = values[:cooldown]
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
      sound: self.class.bullet_sound
    )
  end

  SAMPLE_RATE = 48_000

  def self.bullet_sound
    @bullet_sound ||= generate_bullet_sound
  end

  def self.generate_bullet_sound
    # Synthesizer.new(48000)
    #            .sine_wave(100, 0.25)
    #            .add_harmonics_up_to(10)
    #            .normalize(0.1)
    #            .generate
    Synthesizer.new(SAMPLE_RATE)
               .square_wave(440)
               .modulate_pulse_width(5, 0.8)
               .vibrato(3, 0.8)
               .normalize(0.1)
               .generate(1)
               .tap { |sound|
      $last_sound_plot = Util::WaveformPlotter.new(w: 320, h: 60, samples_per_pixel: 30, max_amplitude: 0.2).plot(sound)
    }
    # Synthesizer.new(48000)
    #            .load_samples('resources/track.txt')
    #            .filter(1000)
    #            .filter(2000)
    #            .generate
  end

  $args.debug.on_reset do
    instance_variable_set('@bullet_sound', nil)
  end
end
