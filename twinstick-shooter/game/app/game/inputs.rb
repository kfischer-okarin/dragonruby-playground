require 'app/game/inputs/directional_input.rb'

class Game
  # Interface for input
  class Inputs
    def self.direction
      @direction ||= KeyboardDirectionalInput.new(:w, :a, :s, :d)
    end

    def self.fire_direction
      @fire_direction ||= KeyboardDirectionalInput.new(:up, :left, :down, :right)
    end

    def initialize(args)
      @args = args
      @direction_x, @direction_y = Inputs.direction.value(@args.inputs)
      @fire_direction_x, @fire_direction_y = Inputs.fire_direction.value(@args.inputs)
    end

    def direction
      [@direction_x, @direction_y]
    end

    def fire_direction
      [@fire_direction_x, @fire_direction_y]
    end
  end
end
