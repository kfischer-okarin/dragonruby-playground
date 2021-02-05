require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/resources.rb'

require 'app/game/inputs.rb'
require 'app/game/outputs.rb'
require 'app/sprites.rb'

module Direction
  ALL = %i[up down left right].freeze
  OPPOSITE = { left: :right, right: :left, up: :down, down: :up }.freeze
  VECTOR = { left: [-1, 0], right: [1, 0], up: [0, 1], down: [0, -1] }.freeze

  def self.opposite_of(direction)
    OPPOSITE[direction]
  end
end

class InitialRoom
  class << self
    def available_directions
      Direction::ALL
    end

    def number_of_doors
      (1..4).to_a.sample
    end

    def room_type_in_direction(_direction)
      :unknown
    end

    def doors
      []
    end
  end
end

class PossibleRoomAt
  attr_reader :doors, :available_directions

  def initialize(state, position)
    @state = state
    @position = position
    @doors = []
    @available_directions = []
    set_doors_and_available_positions
  end

  def number_of_doors
    (@doors.size..@available_directions.size).to_a.sample
  end

  def room_type_in_direction(direction)
    @doors.include?(direction) ? :generated : :unknown
  end

  private

  def set_doors_and_available_positions
    Direction::ALL.each do |direction|
      neighbor_room = room_in_direction(direction)
      if neighbor_room
        door_is_required(direction) if neighbor_room[Direction.opposite_of(direction)]
      else
        door_is_possible(direction)
      end
    end
  end

  def room_in_direction(direction)
    neighbor_position = Room.position_next_to(@position, direction)
    Room.at(@state, neighbor_position)
  end

  def door_is_required(direction)
    @doors << direction
    door_is_possible(direction)
  end

  def door_is_possible(direction)
    @available_directions << direction
  end
end

class RoomGenerator
  def generate(conditions)
    door_directions = pick_door_directions(conditions)

    { light: false }.tap { |result|
      door_directions.each do |direction|
        result[direction] = conditions.room_type_in_direction(direction)
      end
    }
  end

  def pick_door_directions(conditions)
    [].tap { |result|
      result.concat conditions.doors
      doors_to_generate = conditions.number_of_doors - result.size
      doors_to_generate.times do
        result << (conditions.available_directions - result).sample
      end
    }
  end
end

module Room
  class << self
    def at(state, location)
      state.rooms[location]
    end

    def current(state)
      at(state, state.location)
    end

    def generate(state, position, conditions)
      room = $room_generator.generate(conditions)
      state.rooms[position] = room
    end

    def position_next_to(position, direction)
      direction_vector = Direction::VECTOR[direction]
      [position.x + direction_vector.x, position.y + direction_vector.y]
    end

    def generate_unknown_neighbors(state, position)
      room = at(state, position)
      unknown_directions = Direction::ALL.select { |direction| room[direction] == :unknown }
      unknown_directions.each do |direction|
        new_position = position_next_to(position, direction)
        generate(state, new_position, PossibleRoomAt.new(state, new_position))
        room[direction] = :generated
      end
    end
  end
end

def setup(args)
  $inputs = Game::Inputs.new
  $outputs = Game::Outputs.new
  $room_generator = RoomGenerator.new

  Sprites.prepare
  args.state.rooms = {}
  Room.generate(args.state, [0, 0], InitialRoom)
  Room.generate_unknown_neighbors(args.state, [0, 0])
  args.state.location = [0, 0]
  $non_update_frames = 0
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

def tick_15fps(state, inputs)
  room = Room.current(state)
  room[:light] = !room[:light] if inputs.toggle_light
end

def render(args)
  render_room(Room.current(args.state))
  $outputs.process(args)
end

def tick(args)
  setup(args) if args.tick_count.zero?

  $inputs.collect args.inputs

  if $non_update_frames < 3
    $non_update_frames += 1
  else
    tick_15fps(args.state, $inputs)
    $non_update_frames = 0
    $inputs = Game::Inputs.new
  end

  render(args)
end
