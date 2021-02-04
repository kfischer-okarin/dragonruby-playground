require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/resources.rb'

require 'app/game/outputs.rb'
require 'app/sprites.rb'

def setup(args)
  $outputs = Game::Outputs.new

  Sprites.prepare
  args.state.room = { up: rand > 0.5, left: rand > 0.5, right: rand > 0.5, down: rand > 0.5 }
end

def wall_type(room, wall)
  room[wall] ? :wall_with_door : :wall
end

def render_room(room)
  left = ($outputs.w - Sprites::WALL_LENGTH).half
  bottom = ($outputs.h - Sprites::WALL_LENGTH).half
  $outputs.render_sprite left, bottom, wall_type(room, :down)
  $outputs.render_sprite left, bottom + Sprites::WALL_LENGTH, wall_type(room, :up)
  $outputs.render_sprite left, bottom, wall_type(room, :left), angle: 90, angle_anchor_x: 0, angle_anchor_y: 0.5
  $outputs.render_sprite left + Sprites::WALL_LENGTH - 1, 9, wall_type(room, :right), angle: 90, angle_anchor_x: 0, angle_anchor_y: 0.5
end

def tick(args)
  setup(args) if args.tick_count.zero?

  render_room(args.state.room)
  $outputs.process(args)
end
