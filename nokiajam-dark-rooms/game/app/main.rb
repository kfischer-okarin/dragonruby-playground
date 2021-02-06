require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/resources.rb'

require 'app/game/inputs.rb'
require 'app/game/outputs.rb'
require 'app/primitive.rb'
require 'app/renderer.rb'
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

  args.state.animations = {}
  $player_animation = Renderer::Animation.new([
    Renderer::Animation::Frame.new({ w: 11, h: 17, path: 'resources/character.png', source_w: 11, source_h: 17, source_x: 11, source_y: 0 }, 3),
    Renderer::Animation::Frame.new({ w: 11, h: 17, path: 'resources/character.png', source_w: 11, source_h: 17, source_x: 22, source_y: 0 }, 3),
    Renderer::Animation::Frame.new({ w: 11, h: 17, path: 'resources/character.png', source_w: 11, source_h: 17, source_x: 11, source_y: 0 }, 3),
    Renderer::Animation::Frame.new({ w: 11, h: 17, path: 'resources/character.png', source_w: 11, source_h: 17, source_x: 0, source_y: 0 }, 3)
  ]).with_strategy(Renderer::Animation::Looping)
  $player_animation.start(args.state, :player)

  Sprites.prepare
  args.state.rooms = {}
  Room.generate(args.state, [0, 0], InitialRoom)
  Room.generate_unknown_neighbors(args.state, [0, 0])
  args.state.location = [0, 0]
  $non_update_frames = 0
end

def tick_15fps(state, inputs)
  room = Room.current(state)
  room[:light] = !room[:light] if inputs.toggle_light
  # $player_animation.tick(state, :player)
end

class Scene
  def self.render(args)
    Renderer::Room.render(Room.current(args.state))

    $outputs.render $player_animation.rendered(args.state, :player, x: Renderer::Room::LEFT + 9, y: Renderer::Room::BOTTOM + 8)
    $outputs.process(args)
  end
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

  Scene.render(args)
end
