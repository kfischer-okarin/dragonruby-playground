require 'lib/synthesizer/envelope_generator.rb'
require 'lib/synthesizer/generators.rb'
require 'lib/synthesizer/modulators.rb'

class Synthesizer
  attr_reader :generator

  def initialize(sample_rate)
    @generator = nil
    @modulators = []
    @sample_rate = sample_rate
    @envelope = nil
    @post_processors = []
  end

  def sine_wave(frequency, opts = nil)
    args = { sample_rate: @sample_rate, frequency: frequency }.merge(opts || {})
    @generator = Generators::Sine.new(args)
    self
  end

  def sawtooth_wave(frequency, opts = nil)
    args = { sample_rate: @sample_rate, frequency: frequency }.merge(opts || {})
    @generator = Generators::Sawtooth.new(args)
    self
  end

  def square_wave(frequency, opts = nil)
    args = { sample_rate: @sample_rate, frequency: frequency }.merge(opts || {})
    @generator = Generators::Square.new(args)
    self
  end

  def sawtooth_from_harmonics(frequency, harmonics_count, opts = nil)
    @generator = Generators::SawToothFromHarmonics.new(@sample_rate, frequency, harmonics_count, opts)
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
    @modulators << Modulators::General.new(
      sample_rate: @sample_rate,
      attribute: :frequency,
      base_value: @generator.frequency,
      frequency: frequency,
      amount: amount
    )
    self
  end

  def tremolo(frequency, amount)
    @modulators << Modulators::General.new(
      sample_rate: @sample_rate,
      attribute: :amplitude,
      base_value: @generator.amplitude,
      frequency: frequency,
      amount: amount
    )
    self
  end

  def modulate_pulse_width(frequency, amount)
    @modulators << Modulators::General.new(
      sample_rate: @sample_rate,
      attribute: :pulse_width,
      base_value: @generator.pulse_width,
      frequency: frequency,
      amount: amount
    )
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

  def next
    @modulators.each do |modulator|
      modulator.apply_to(@generator)
    end
    value = @generator.generate
    value *= @envelope.generate if @envelope
    value
  end

  def generate(length)
    sample_count = (length * @sample_rate).ceil
    release_index = sample_count - (@envelope.release_duration * @sample_rate).ceil if @envelope
    result = sample_count.ceil.map_with_index { |index|
      value = self.next
      @envelope.release if @envelope && index == release_index
      value
    }
    @post_processors.each do |processor|
      processor.call(result)
    end
    result
  end
end
