require 'lib/synthesizer/generators.rb'
require 'lib/synthesizer/util.rb'

module Modulators
  class General
    def initialize(args)
      Util::Params[args].require!(:sample_rate, :attribute, :base_value, :frequency, :amount)
      @attribute = args[:attribute]
      @base_value = args[:base_value]
      @wave_generator = Generators::Sine.new(
        sample_rate: args[:sample_rate],
        frequency: args[:frequency],
        amplitude: args[:amount]
      )
    end

    def apply_to(generator)
      generator.send(:"#{@attribute}=", @base_value * (1 + @wave_generator.generate))
    end
  end
end
