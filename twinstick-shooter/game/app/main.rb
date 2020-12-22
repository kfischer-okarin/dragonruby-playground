require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'
require 'lib/set.rb'
require 'lib/vector_extensions.rb'

require 'app/resources.rb'
require 'app/primitives.rb'
require 'app/game.rb'
require 'app/main_scene.rb'

def tick(args)
  $game = Game.new(MainScene.new) if args.tick_count.zero?
  $game.tick(args)
end
