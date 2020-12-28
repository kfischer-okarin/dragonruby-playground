require 'lib/synthesizer/util.rb'

module Generators
  class Sine
    TWO_PI = 2 * Math::PI

    attr_reader :frequency, :phase_shift, :next_phase
    attr_accessor :amplitude

    def initialize(args)
      Util::Params[args].require!(:sample_rate, :frequency).permit!(:amplitude, :phase_shift)

      @sample_rate = args[:sample_rate]
      self.frequency = args[:frequency]
      @amplitude = args[:amplitude] || 1.0
      @phase_shift = args[:phase_shift] || 0
      self.next_phase = @phase_shift
    end

    def frequency=(value)
      @frequency = value
      @sample_increment = TWO_PI * value / @sample_rate
    end

    def phase_shift=(value)
      self.next_phase += (value - @phase_shift)
      @phase_shift = value
    end

    def next_phase=(value)
      @next_phase = value % TWO_PI
    end

    def next
      phase = @next_phase
      self.next_phase += @sample_increment
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
    attr_reader :pulse_width

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

    def next
      @generators.reduce(0) { |memo, generator| memo + generator.next }
    end
  end
end
