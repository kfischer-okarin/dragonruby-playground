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

  class Synthesizer
    def self.generate_sine_wave(sample_rate, frequency, length)
      period_length = (sample_rate / frequency).ceil
      one_period = period_length.map_with_index { |i|
        Math.sin((2 * Math::PI) * (i / period_length))
      }
      one_period * (frequency * length).ceil
    end

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @result = []
    end

    def generate
      @result
    end

    def sine_wave(frequency, length)
      @frequency = frequency
      @length = length
      @result = self.class.generate_sine_wave(@sample_rate, frequency, length)
      self
    end

    def add_harmonics_up_to(n)
      (2..n).each do |harmonic|
        sine = self.class.generate_sine_wave(@sample_rate, @frequency * harmonic, @length)
        @result.size.times do |k|
          @result[k] += sine[k]
        end
      end
      self
    end

    def envelope_adsr(attack, decay, sustain, release)
      full_amplitude_index = (attack * @sample_rate).ceil
      sustain_amplitude_index = full_amplitude_index + (decay * @sample_rate).ceil
      release_index = @result.size - (release * @sample_rate).ceil
      @result.each_with_index do |value, index|
        @result[index] = value * if index <= full_amplitude_index
                                   index / full_amplitude_index
                                 elsif index <= sustain_amplitude_index
                                   progress = (index - full_amplitude_index) / (sustain_amplitude_index - full_amplitude_index)
                                   1 * (1 - progress) + sustain * progress
                                 elsif index <= release_index
                                   sustain
                                 else
                                   progress = (index - release_index) / (@result.size - release_index)
                                   sustain * (1 - progress)
                                 end
                                end
      self
    end

    def normalize(amplitude = 1.0)
      factor = amplitude / @result.max
      @result.size.times do |k|
        @result[k] *= factor
      end
      self
    end
  end

  SAMPLE_RATE = 48000

  def self.bullet_sound
    @bullet_sound ||= generate_bullet_sound
  end

  def self.generate_bullet_sound
    Synthesizer.new(48000)
               .sine_wave(440, 0.25)
               .add_harmonics_up_to(20)
               .normalize(0.1)
               .envelope_adsr(0.05, 0.05, 0.6, 0.5)
               .generate
  end
end
