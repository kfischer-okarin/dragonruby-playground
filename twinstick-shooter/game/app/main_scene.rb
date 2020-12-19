class MainScene
  attr_reader :next_scene

  def initialize
    @movement_direction = [0, 0]
    @position = [160, 90]
  end

  def tick(game_inputs)
    @movement_direction = game_inputs.direction
    @position = @position.add_vector @movement_direction
  end

  def render(game_outputs)
    game_outputs.draw [@position.x, @position.y, 20, 20, 255, 0, 0].solid
  end
end
