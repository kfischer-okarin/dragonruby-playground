require 'lib/low_resolution_canvas.rb'

class Game
  # Interface for outputs
  class Outputs
    def initialize
      @canvas = DRT::LowResolutionCanvas.new([Game::W, Game::H])
    end

    def draw(primitive)
      @canvas.primitives << primitive
    end

    def process(args)
      args.outputs.background_color = [0, 0, 0]
      args.outputs.primitives << @canvas
    end
  end
end
