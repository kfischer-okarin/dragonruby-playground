require 'lib/low_resolution_canvas.rb'

class Game
  # Interface for outputs
  class Outputs
    def initialize
      @canvas = DRT::LowResolutionCanvas.new([Game::W, Game::H])
      @samples = []
      @audio_id = 0
    end

    def draw(primitive)
      @canvas.primitives << primitive
    end

    def play_sample(sample)
      @samples << sample
    end

    def process(args)
      args.outputs.background_color = [0, 0, 0]
      args.outputs.primitives << @canvas

      play_next_sample(args) until @samples.empty?
    end

    private

    def play_next_sample(args)
      sample = @samples.pop
      args.audio[@audio_id] = {
        input: [1, 48000, sample]
      }
      @audio_id += 1
    end
  end
end
