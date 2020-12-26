require 'lib/synthesizer/util.rb'

module Generators
  class Sine
    TWO_PI = 2 * Math::PI

    attr_reader :frequency
    attr_accessor :amplitude, :phase_shift

    def initialize(args)
      Util::Params[args].require!(:sample_rate, :frequency).permit!(:amplitude, :phase_shift)

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

  class Sawtooth < Sine
    def value_of_phase(phase)
      1 - (phase / Math::PI)
    end
  end

  class Square < Sine
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

  class SawToothFromHarmonics
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
end
