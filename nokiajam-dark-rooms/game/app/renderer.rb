module Renderer
  class Animation
    Frame = Struct.new(:primitive, :duration)

    class OneTime
      def self.next_frame_index(frames, animation_state)
        [animation_state[:frame_index] + 1, frames.size - 1].min
      end
    end

    class Looping
      def self.next_frame_index(frames, animation_state)
        (animation_state[:frame_index] + 1) % frames.size
      end
    end

    def initialize(frames)
      @frames = frames
      @strategy = OneTime
    end

    def with_strategy(strategy)
      @strategy = strategy
      self
    end

    def reset(state, id)
      state.animations[id] = { frame_index: 0, frame_time: 0 }
    end

    def tick(state, id)
      advance_frame_time(state.animations[id])
    end

    def rendered(state, id, values)
      animation_state = state.animations[id]
      current_frame(animation_state).primitive.merge(values)
    end

    private

    def current_frame(animation_state)
      @frames[animation_state[:frame_index]]
    end

    def advance_frame_time(animation_state)
      animation_state[:frame_time] += 1
      frame_finished = animation_state[:frame_time] > current_frame(animation_state).duration
      return unless frame_finished

      animation_state[:frame_index] = @strategy.next_frame_index(@frames, animation_state)
      animation_state[:frame_time] = 0
    end
  end

  module Room
    SIZE = 33
    DOOR_SIZE = 11
    LEFT = (Game::Outputs::SCREEN_W - SIZE).idiv(2)
    RIGHT = LEFT + SIZE - 1
    BOTTOM = (Game::Outputs::SCREEN_H - SIZE).idiv(2)
    TOP = BOTTOM + SIZE - 1

    class << self
      def rendered(room, neighboring_rooms)
        light_beams(neighboring_rooms).tap { |result|
          result << light if room[:light]
        }
      end

      def walls(room, neighboring_rooms)
        return [] if room[:light]

        [].tap { |result|
          result << Wall.up(room) unless neighboring_rooms.dig(:up, :light)
          result << Wall.down(room) unless neighboring_rooms.dig(:down, :light)
          result << Wall.left(room) unless neighboring_rooms.dig(:left, :light)
          result << Wall.right(room) unless neighboring_rooms.dig(:right, :light)
        }
      end

      def light_beams(neighboring_rooms)
        [].tap { |result|
          result << LightBeam.from_up if neighboring_rooms.dig(:up, :light)
          result << LightBeam.from_down if neighboring_rooms.dig(:down, :light)
          result << LightBeam.from_left if neighboring_rooms.dig(:left, :light)
          result << LightBeam.from_right if neighboring_rooms.dig(:right, :light)
        }
      end

      def light
        Primitive.rect(x: LEFT, y: BOTTOM, w: SIZE, h: SIZE, color: :white)
      end
    end
  end

  module Wall
    ROTATED_BY_90_DEGREES = { angle: 90, angle_anchor_x: 0, angle_anchor_y: 0 }.freeze

    LEFT = Room::LEFT - 1
    RIGHT = Room::RIGHT + 1
    BOTTOM = Room::BOTTOM - 1
    TOP = Room::TOP + 1

    class << self
      def wall_type(room, wall)
        room[wall] ? :wall_with_door_dark : :wall_dark
      end

      def down(room)
        Primitive.sprite(wall_type(room, :down), x: LEFT, y: BOTTOM, color: :white)
      end

      def up(room)
        Primitive.sprite(wall_type(room, :up), x: LEFT, y: TOP, color: :white)
      end

      def left(room)
        Primitive.sprite(wall_type(room, :left), x: LEFT + 1, y: BOTTOM, color: :white, **ROTATED_BY_90_DEGREES)
      end

      def right(room)
        Primitive.sprite(wall_type(room, :right), x: RIGHT + 1, y: BOTTOM, color: :white, **ROTATED_BY_90_DEGREES)
      end
    end
  end

  module LightBeam
    class << self
      def from_down
        Primitive.sprite(:light_beam, x: Wall::LEFT + 10, y: Wall::BOTTOM, color: :white)
      end

      def from_up
        Primitive.sprite(:light_beam, x: Wall::LEFT + 11, y: Wall::TOP + 1, angle: 180, angle_anchor_y: 0, color: :white)
      end

      def from_right
        Primitive.sprite(:light_beam, x: Wall::RIGHT - 6, y: Wall::BOTTOM + 17, angle: 90, angle_anchor_y: 0, color: :white)
      end

      def from_left
        Primitive.sprite(:light_beam, x: Wall::LEFT - 7, y: Wall::BOTTOM + 18, angle: 270, angle_anchor_y: 0, color: :white)
      end
    end
  end
end
