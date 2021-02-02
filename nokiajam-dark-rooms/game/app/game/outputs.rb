require 'lib/low_resolution_canvas.rb'

class Game
  # Specialized Outputs for Nokia Jam
  class Outputs
    W = 84
    H = 48

    BG_COLOR = [199, 240, 216].freeze
    FG_COLOR = [67, 82, 61].freeze

    def initialize
      @canvas = DRT::LowResolutionCanvas.new([W, H])
    end

    def process(args)
      args.outputs.background_color = BG_COLOR
      @canvas.background_color = BG_COLOR
      args.outputs.primitives << @canvas
    end
  end
end
