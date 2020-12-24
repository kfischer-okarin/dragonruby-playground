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
    class << self
      attr_accessor :last_generated_plot

      def generate_plot(sound)
        w = 320
        h = 60
        samples_per_pixel = 20
        [].tap { |result|
          last_point = nil
          w.times do |x|
            current_point = [x, sound[x * samples_per_pixel] * 300 + 30]
            result << [last_point, current_point, 255, 0, 0].line if last_point
            last_point = current_point
          end
        }
      end
    end

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @post_processors = []
    end

    def sine_wave(frequency, opts = nil)
      options = opts || {}
      amplitude = options[:amplitude] || 1.0
      phase_shift = options[:phase_shift] || 0
      sample_increment = 2 * Math::PI * frequency / @sample_rate
      @generate_sample = proc { |index| Math.sin(index * sample_increment + phase_shift) * amplitude }
      self
    end

    def saw_tooth_from_harmonics(frequency, harmonics_count, opts = nil)
      options = opts || {}
      amplitude = options[:amplitude] || 1.0
      phase_shift = options[:phase_shift] || 0

      @generate_sample = proc { |index|
        sample_increments = (1..harmonics_count).map { |harmonic| [harmonic, 2 * Math::PI * frequency * harmonic / @sample_rate] }.to_h
        (1..harmonics_count).map { |harmonic|
          Math.sin(index * sample_increments[harmonic] + phase_shift) * amplitude / harmonic
        }.reduce(0, :plus)
      }
      self
    end

    def load_samples(filename)
      samples = $gtk.read_file(filename).split.map(&:to_f)
      @generate_sample = proc { |index| samples[index] || 0 }
      self
    end

    def envelope_adsr(attack, decay, sustain, release)
      full_amplitude_index = (attack * @sample_rate).ceil
      sustain_amplitude_index = ((attack + decay) * @sample_rate).ceil
      release_samples = (release * @sample_rate).ceil
      generator = @generate_sample
      @generate_sample = lambda { |index, sample_count|
        release_index = sample_count - release_samples

        factor = if index <= full_amplitude_index
                   index / full_amplitude_index
                 elsif index <= sustain_amplitude_index
                   progress = (index - full_amplitude_index) / (sustain_amplitude_index - full_amplitude_index)
                   1 * (1 - progress) + sustain * progress
                 elsif index <= release_index
                   sustain
                 else
                   progress = (index - release_index) / release_samples
                   sustain * (1 - progress)
                 end

        generator.call(index, sample_count) * factor
      }
      self
    end

    def normalize(amplitude = 1.0)
      @post_processors << lambda { |samples|
        factor = amplitude / samples.max
        samples.size.times do |k|
          samples[k] *= factor
        end
      }
      self
    end

    def generate(length)
      sample_count = (length * @sample_rate).ceil
      result = sample_count.ceil.map_with_index { |index|
        @generate_sample.call(index, sample_count)
      }
      @post_processors.each do |processor|
        processor.call(result)
      end
      self.class.last_generated_plot = self.class.generate_plot(result)
      result
    end
  end

  SAMPLE_RATE = 48000

  def self.bullet_sound
    @bullet_sound ||= generate_bullet_sound
  end

  def self.generate_bullet_sound
    # Synthesizer.new(48000)
    #            .sine_wave(100, 0.25)
    #            .add_harmonics_up_to(10)
    #            .normalize(0.1)
    #            .generate
    Synthesizer.new(48000)
               .sine_wave(440)
               .envelope_adsr(0.05, 0.05, 0.6, 0.5)
               .normalize(0.1)
               .generate(0.25)
    # Synthesizer.new(48000)
    #            .load_samples('resources/track.txt')
    #            .filter(1000)
    #            .filter(2000)
    #            .generate
  end
end
