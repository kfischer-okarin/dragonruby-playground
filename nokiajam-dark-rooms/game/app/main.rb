require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/resources.rb'

require 'app/game/outputs.rb'

def setup(_args)
  $outputs = Game::Outputs.new

  $outputs.create_sprite(
    :image,
    [
      ' XXXX ',
      'X    X',
      'X    X',
      ' XXXX '
    ]
  )
end

def tick(args)
  setup(args) if args.tick_count.zero?

  $outputs.render_sprite 0, 0, :image
  $outputs.process(args)
end
