require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/resources.rb'

require 'app/game/outputs.rb'

def setup(_args)
  $outputs = Game::Outputs.new
end

def tick(args)
  setup(args) if args.tick_count.zero?

  $outputs.process(args)
end
