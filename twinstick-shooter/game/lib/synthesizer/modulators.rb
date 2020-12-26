require 'lib/synthesizer/generators.rb'

module Modulators
  class Vibrato
    def initialize(sample_rate, original_frequency, effect_frequency, effect_amplitude)
      @original_frequency = original_frequency
      @wave_generator = Generators::Sine.new(
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
      @wave_generator = Generators::Sine.new(
        sample_rate: sample_rate,
        frequency: effect_frequency,
        amplitude: effect_amplitude
      )
    end

    def apply_to(generator)
      generator.amplitude = @original_amplitude * (1 + @wave_generator.generate)
    end
  end
end
