require 'lib/synthesizer/generators.rb'
require 'lib/synthesizer/util.rb'

class Modulator
  GENERATORS = {
    sine: Generators::Sine,
    sawtooth: Generators::Sawtooth,
    square: Generators::Square
  }.freeze

  def initialize(args)
    Util::Params[args].require!(:sample_rate, :attribute, :base_value, :generator)
    @attribute = args[:attribute]
    @base_value = args[:base_value]
    generator_params = args[:generator].dup.merge(sample_rate: args[:sample_rate])
    @wave_generator = build_generator(generator_params)
  end

  def apply_to(generator)
    generator.send(:"#{@attribute}=", @base_value * (1 + @wave_generator.generate))
  end

  private

  def build_generator(generator_params)
    type = generator_params.delete(:type) || :sine
    generator_class = GENERATORS[type]
    generator_class.new(generator_params)
  end
end
