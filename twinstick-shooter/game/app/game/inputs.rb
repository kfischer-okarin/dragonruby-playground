class Game
  # Interface for input
  class Inputs
    def initialize(args)
      @args = args
      calc_direction
    end

    def direction
      [@direction_x, @direction_y]
    end

    private

    def calc_direction
      key_held = @args.inputs.keyboard.key_held
      @direction_x = 0
      @direction_x = -1 if key_held.left
      @direction_x = 1 if key_held.right
      @direction_y = 0
      @direction_y = -1 if key_held.down
      @direction_y = 1 if key_held.up
    end
  end
end
