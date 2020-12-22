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

  SAMPLE_RATE = 48000

  def self.generate_sine(frequency, length)
    period_length = (SAMPLE_RATE / frequency).ceil
    one_period = period_length.map_with_index { |i|
      Math.sin((2 * Math::PI) * (i / period_length))
    }
    one_period * (frequency * length).ceil
  end

  def self.adsr(sound, attack, decay, sustain, release)
    full_amplitude_index = (attack * SAMPLE_RATE).ceil
    sustain_amplitude_index = full_amplitude_index + (decay * SAMPLE_RATE).ceil
    release_index = sound.size - (release * SAMPLE_RATE).ceil
    sound.map_with_index { |value, index|
      value * if index <= full_amplitude_index
                index / full_amplitude_index
              elsif index <= sustain_amplitude_index
                progress = (index - full_amplitude_index) / (sustain_amplitude_index - full_amplitude_index)
                1 * (1 - progress) + sustain * progress
              elsif index <= release_index
                sustain
              else
                progress = (index - release_index) / (sound.size - release_index)
                sustain * (1 - progress)
              end
    }
  end

  def self.bullet_sound
    @bullet_sound ||= adsr(normalize(generate_bullet_sound, 0.1), 0.05, 0.05, 0.6, 0.5)
  end

  def self.generate_bullet_sound
    length = 0.25
    base_f = 440
    result = [0] * (length * SAMPLE_RATE)
    (1..5).each do |harmonic|
      sine = generate_sine(base_f * harmonic, length)
      result.size.times do |k|
        result[k] += sine[k]
      end
    end
    result
  end

  def self.normalize(sound, amplitude = 1.0)
    max = sound.max
    sound.map { |val| val * amplitude / max }
  end
end
