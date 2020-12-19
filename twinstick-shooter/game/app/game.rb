require 'app/game/inputs.rb'
require 'app/game/outputs.rb'

# Main interface between DragonRuby and the rest of the game
# Manages current scene
class Game
  W = 320
  H = 180

  def initialize(first_scene)
    @scene = first_scene
    @outputs = Outputs.new
  end

  def tick(args)
    @scene = @scene.next_scene || @scene

    @scene.tick(Inputs.new(args))
    @scene.render(@outputs)

    @outputs.process(args)
  end

  def quit
    $gtk.request_quit
  end
end
