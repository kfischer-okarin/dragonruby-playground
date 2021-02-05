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

class RoomRenderer
  class << self
    def render_walls(room)
      return if room[:light]

      $outputs.render_sprite left - 1, bottom - 1, wall_type(room, :down), wall_render_options(room, :down)
      $outputs.render_sprite left - 1, top + 1, wall_type(room, :up), wall_render_options(room, :up)
      $outputs.render_sprite left, bottom - 1, wall_type(room, :left), wall_render_options(room, :left)
      $outputs.render_sprite right + 2, bottom - 1, wall_type(room, :right), wall_render_options(room, :right)
    end

    def wall_type(room, wall)
      room[wall] ? :wall_with_door_dark : :wall_dark
    end

    def wall_render_options(_room, wall)
      {}.tap { |result|
        result.update(angle: 90, angle_anchor_x: 0, angle_anchor_y: 0) if %i[left right].include?(wall)
      }
    end

    def render_room_light(_room)
      $outputs.render_rect left, bottom, room_size, room_size
    end

    def render_light_beams(room)
      $outputs.render_sprite left + 6, top + 1, :light_beam if room[:up]
      $outputs.render_sprite left + 7, bottom, :light_beam, angle: 180, angle_anchor_y: 0 if room[:down]
      $outputs.render_sprite left - 7, bottom + 13, :light_beam, angle: 90, angle_anchor_y: 0 if room[:left]
      $outputs.render_sprite right - 6, bottom + 14, :light_beam, angle: 270, angle_anchor_y: 0 if room[:right]
    end

    def room_size
      Sprites::WALL_LENGTH - 2
    end

    def left
      ($outputs.w - room_size).idiv 2
    end

    def right
      left + room_size - 1
    end

    def bottom
      ($outputs.h - room_size).idiv 2
    end

    def top
      bottom + room_size - 1
    end
  end
end

def render_room(room)
  RoomRenderer.render_walls(room)
  return unless room[:light]

  RoomRenderer.render_room_light(room)
  RoomRenderer.render_light_beams(room)
end

def tick(args)
  setup(args) if args.tick_count.zero?

  inputs = Game::Inputs.new(args.inputs)
  args.state.room[:light] = !args.state.room[:light] if inputs.toggle_light

  render_room(args.state.room)
  $outputs.process(args)
end
