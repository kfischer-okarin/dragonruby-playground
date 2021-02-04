require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/resources.rb'

require 'app/game/inputs.rb'
require 'app/game/outputs.rb'
require 'app/sprites.rb'

def setup(args)
  $outputs = Game::Outputs.new

  Sprites.prepare
  args.state.room = { up: rand > 0.5, left: rand > 0.5, right: rand > 0.5, down: rand > 0.5, light: false }
end

def wall_type(room, wall)
  if room[:light]
    room[wall] ? :wall_with_door : :wall
  else
    room[wall] ? :wall_with_door_dark : :wall_dark
  end
end

def wall_render_options(room, wall)
  {}.tap { |result|
    result.update(angle: 90, angle_anchor_x: 0, angle_anchor_y: 0.5) if %i[left right].include?(wall)
    result[:invert] = true if room[:light]
  }
end

def render_room(room)
  left = ($outputs.w - Sprites::WALL_LENGTH).half
  right = left + Sprites::WALL_LENGTH - 1
  bottom = ($outputs.h - Sprites::WALL_LENGTH).half
  top = bottom + Sprites::WALL_LENGTH - 1
  $outputs.render_sprite left, bottom, wall_type(room, :down), wall_render_options(room, :down)
  $outputs.render_sprite left, top, wall_type(room, :up), wall_render_options(room, :up)
  $outputs.render_sprite left, bottom - 1, wall_type(room, :left), wall_render_options(room, :left)
  $outputs.render_sprite right, bottom - 1, wall_type(room, :right), wall_render_options(room, :right)
  return unless room[:light]

  $outputs.render_rect left + 1, bottom + 1, Sprites::WALL_LENGTH - 2, Sprites::WALL_LENGTH - 2
  $outputs.render_sprite left + 7, top, :light_beam if room[:up]
  $outputs.render_sprite left + 1, bottom + 7, :light_beam, angle: 90, angle_anchor_x: 0, angle_anchor_y: 0 if room[:left]
  $outputs.render_sprite right, bottom + 22, :light_beam, angle: 270, angle_anchor_x: 0, angle_anchor_y: 0 if room[:right]
  $outputs.render_sprite left + 22, bottom + 1, :light_beam, angle: 180, angle_anchor_x: 0, angle_anchor_y: 0 if room[:down]
end

def tick(args)
  setup(args) if args.tick_count.zero?

  inputs = Game::Inputs.new(args.inputs)
  args.state.room[:light] = !args.state.room[:light] if inputs.toggle_light

  render_room(args.state.room)
  $outputs.process(args)
end
