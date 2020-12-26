class Params
  def self.[](value_hash)
    new(value_hash)
  end

  def initialize(value_hash)
    @value_hash = value_hash
    @permitted = []
  end

  def permit!(*keys)
    @permitted.concat(keys)
    unknown = @value_hash.keys.reject { |key| @permitted.include? key }
    raise "Unknown keyword arguments: #{unknown}" unless unknown.empty?

    self
  end

  def require!(*keys)
    @permitted.concat(keys)
    missing = keys.reject { |key| @value_hash.key? key }
    raise "Required keyword arguments missing: #{missing}" unless missing.empty?

    self
  end
end

class Synthesizer
  class SineGenerator
    TWO_PI = 2 * Math::PI

    attr_reader :frequency
    attr_accessor :amplitude, :phase_shift

    def initialize(args)
      Params[args].require!(:sample_rate, :frequency).permit!(:amplitude, :phase_shift)
      @sample_rate = args[:sample_rate]
      self.frequency = args[:frequency]
      @amplitude = args[:amplitude] || 1.0
      @phase_shift = args[:phase_shift] || 0
      @last_phase = 0
      @next_phase = 0
    end

    def frequency=(value)
      @frequency = value
      @sample_increment = TWO_PI * value / @sample_rate
    end

    def generate
      phase = (@next_phase + @phase_shift) % TWO_PI
      @next_phase = (@next_phase + @sample_increment) % TWO_PI
      value_of_phase(phase) * @amplitude
    end

    def value_of_phase(phase)
      Math.sin(phase)
    end
  end

  class SawToothFromHarmonicsGenerator
    attr_reader :frequency, :amplitude, :phase_shift

    def initialize(sample_rate, frequency, harmonics_count, opts = nil)
      @frequency = frequency
      options = opts || {}
      @amplitude = options[:amplitude] || 1.0
      @phase_shift = options[:phase_shift] || 0
      @generators = (1..harmonics_count).map { |harmonic|
        SineGenerator.new(sample_rate, @frequency * harmonic, phase_shift: @phase_shift, amplitude: @amplitude / harmonic)
      }
    end

    def frequency=(value)
      @frequency = value
      (1..@generators.size).each do |harmonic|
        @generators[harmonic - 1].frequency = value * harmonic
      end
    end

    def amplitude=(value)
      @amplitude = value
      (1..@generators.size).each do |harmonic|
        @generators[harmonic - 1].amplitude = value / harmonic
      end
    end

    def phase_shift=(value)
      @phase_shift = value
      @generators.each do |generator|
        generator.phase_shift = value
      end
    end

    def generate
      @generators.reduce(0) { |memo, generator| memo + generator.generate }
    end
  end

  class SawtoothGenerator < SineGenerator
    def value_of_phase(phase)
      1 - (phase / Math::PI)
    end
  end

  class SquareGenerator < SineGenerator
    def initialize(args)
      self.pulse_width = args.delete(:pulse_width) || 0.5
      super(args)
    end

    def pulse_width=(value)
      @pulse_width = value
      @phase_threshold = TWO_PI * value
    end

    def value_of_phase(phase)
      phase >= @phase_threshold ? -1 : 1
    end
  end

  class EnvelopeGenerator
    Slope = Struct.new(:duration, :level)

    def self.adsr(sample_rate, attack, decay, sustain, release)
      new(sample_rate, [Slope.new(attack, 1), Slope.new(decay, sustain)], [Slope.new(release, 0)])
    end

    def initialize(sample_rate, attack_phases, release_phases)
      @sample_rate = sample_rate
      @phases = {
        attack: attack_phases,
        release: release_phases
      }
      @last_value = 0
      switch_to_phase(:attack, 0)
    end

    def attack
      switch_to_phase(:attack, 0)
    end

    def release
      switch_to_phase(:release, 0)
    end

    def release_duration
      @phases[:release].reduce(0) { |memo, phase| memo + phase.duration }
    end

    def generate
      return @last_value if @mode == :sustain

      value = @last_value + @increment
      @sample_index += 1
      if phase_finished?
        value = @phase.level
        go_to_next_phase
      end

      @last_value = value
    end

    private

    def phase_finished?
      @sample_index >= @phase_sample_count
    end

    def switch_to_phase(mode, index)
      @mode = mode
      @phase_index = index
      @phase = @phases[@mode][@phase_index]
      @sample_index = 0
      @phase_sample_count = (@phase.duration * @sample_rate).ceil
      @increment = (@phase.level - @last_value) / @phase_sample_count
    end

    def go_to_next_phase
      next_phase_index = @phase_index + 1
      mode_finished = @phases[@mode][next_phase_index].nil?
      if mode_finished
        @mode = :sustain
      else
        switch_to_phase(@mode, next_phase_index)
      end
    end
  end

  class Vibrato
    def initialize(sample_rate, original_frequency, effect_frequency, effect_amplitude)
      @original_frequency = original_frequency
      @wave_generator = SineGenerator.new(
        sample_rate: sample_rate,
        frequency: effect_frequency,
        amplitude: effect_amplitude
      )
    end

    def apply_to(generator)
      generator.frequency = @original_frequency * (1 + @wave_generator.generate)
    end
  end

  class Tremolo
    def initialize(sample_rate, original_amplitude, effect_frequency, effect_amplitude)
      @original_amplitude = original_amplitude
      @wave_generator = SineGenerator.new(
        sample_rate: sample_rate,
        frequency: effect_frequency,
        amplitude: effect_amplitude
      )
    end

    def apply_to(generator)
      generator.amplitude = @original_amplitude * (1 + @wave_generator.generate)
    end
  end

  class << self
    attr_accessor :last_generated_plot

    def generate_plot(sound)
      w = 320
      h = 60
      samples_per_pixel = 1
      offset = sound.size - w
      [].tap { |result|
        last_point = nil
        w.times do |x|
          current_point = [x, sound[offset + x * samples_per_pixel] * 300 + h / 2]
          result << [last_point, current_point, 255, 0, 0].line if last_point
          last_point = current_point
        end
      }
    end
  end

  def initialize(sample_rate)
    @generator = nil
    @modulators = []
    @sample_rate = sample_rate
    @envelope = nil
    @post_processors = []
  end

  def sine_wave(frequency, opts = nil)
    args = { sample_rate: @sample_rate, frequency: frequency }.merge(opts || {})
    @generator = SineGenerator.new(args)
    self
  end

  def sawtooth_wave(frequency, opts = nil)
    args = { sample_rate: @sample_rate, frequency: frequency }.merge(opts || {})
    @generator = SawtoothGenerator.new(args)
    self
  end

  def square_wave(frequency, opts = nil)
    args = { sample_rate: @sample_rate, frequency: frequency }.merge(opts || {})
    @generator = SquareGenerator.new(args)
    self
  end

  def sawtooth_from_harmonics(frequency, harmonics_count, opts = nil)
    @generator = SawToothFromHarmonicsGenerator.new(@sample_rate, frequency, harmonics_count, opts)
    self
  end

  def load_samples(filename)
    samples = $gtk.read_file(filename).split.map(&:to_f)
    @generate_sample = proc { |index| samples[index] || 0 } # TODO: FIX
    self
  end

  # TODO: 5 Stage Attack Decay Slope Sustain Release
  #   - ADSSR(attack, attack_level, decay, break_point, slope, sustain_level, release)
  #       = Attack: [SlopePhase(attack, attack_level), SlopePhase(decay, break_point), SlopePhase(slope, sustain_level)],
  #         Release: [SlopePhase(release, 0)]
  def envelope_adsr(attack, decay, sustain, release)
    @envelope = EnvelopeGenerator.adsr(@sample_rate, attack, decay, sustain, release)
    self
  end

  def vibrato(frequency, amount)
    @modulators << Vibrato.new(@sample_rate, @generator.frequency, frequency, amount)
    self
  end

  def tremolo(frequency, amount)
    @modulators << Tremolo.new(@sample_rate, @generator.amplitude, frequency, amount)
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
    release_index = sample_count - (@envelope.release_duration * @sample_rate).ceil if @envelope
    result = sample_count.ceil.map_with_index { |index|
      @modulators.each do |modulator|
        modulator.apply_to(@generator)
      end
      value = @generator.generate
      if @envelope
        value *= @envelope.generate
        @envelope.release if index == release_index
      end
      value
    }
    @post_processors.each do |processor|
      processor.call(result)
    end
    self.class.last_generated_plot = self.class.generate_plot(result)
    result
  end
end
