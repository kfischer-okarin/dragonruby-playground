require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/resources.rb'

require 'app/game/outputs.rb'

WALL_LENGTH = 30
DOOR_SIZE = 8
ROOM_LEFT = (84 - WALL_LENGTH).half
ROOM_BOTTOM = (48 - WALL_LENGTH).half

def setup(args)
  $outputs = Game::Outputs.new

  $outputs.create_sprite(:wall, ['X' * WALL_LENGTH])
  $outputs.create_sprite(
    :wall_with_door,
    [
      'X' * (WALL_LENGTH - DOOR_SIZE).half + ' ' * DOOR_SIZE + 'X' * (WALL_LENGTH - DOOR_SIZE).half
    ]
  )
  args.state.room = { up: rand > 0.5, left: rand > 0.5, right: rand > 0.5, down: rand > 0.5 }
end

def wall_type(door)
  door ? :wall_with_door : :wall
end

def render_room(room)
  $outputs.render_sprite ROOM_LEFT, ROOM_BOTTOM, wall_type(room[:down])
  $outputs.render_sprite ROOM_LEFT, ROOM_BOTTOM + WALL_LENGTH, wall_type(room[:up])
  $outputs.render_sprite ROOM_LEFT, ROOM_BOTTOM, wall_type(room[:left]), angle: 90, angle_anchor_x: 0, angle_anchor_y: 0.5
  $outputs.render_sprite ROOM_LEFT + WALL_LENGTH - 1, 9, wall_type(room[:right]), angle: 90, angle_anchor_x: 0, angle_anchor_y: 0.5
end

def tick(args)
  setup(args) if args.tick_count.zero?

  render_room(args.state.room)
  $outputs.process(args)
end
