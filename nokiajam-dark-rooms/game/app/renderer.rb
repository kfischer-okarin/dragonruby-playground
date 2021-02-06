module Renderer
  class << self
    def render(args)
      Room.render(::Room.current(args.state))
      $outputs.process(args)
    end
  end

  module Room
    SIZE = 27
    LEFT = (Game::Outputs::SCREEN_W - SIZE).idiv(2)
    RIGHT = LEFT + SIZE - 1
    BOTTOM = (Game::Outputs::SCREEN_H - SIZE).idiv(2)
    TOP = BOTTOM + SIZE - 1

    class << self
      def render(room)
        render_walls(room)
        return unless room[:light]

        $outputs.render light
        render_light_beams(room)
      end

      def render_walls(room)
        return if room[:light]

        $outputs.render Wall.down(room)
        $outputs.render Wall.up(room)
        $outputs.render Wall.left(room)
        $outputs.render Wall.right(room)
      end

      def render_light_beams(room)
        $outputs.render LightBeam.up_out if room[:up]
        $outputs.render LightBeam.down_out if room[:down]
        $outputs.render LightBeam.left_out if room[:left]
        $outputs.render LightBeam.right_out if room[:right]
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
      def up_out
        Primitive.sprite(:light_beam, x: Wall::LEFT + 7, y: Wall::TOP, color: :white)
      end

      def down_out
        Primitive.sprite(:light_beam, x: Wall::LEFT + 8, y: Wall::BOTTOM + 1, angle: 180, angle_anchor_y: 0, color: :white)
      end

      def left_out
        Primitive.sprite(:light_beam, x: Wall::LEFT - 6, y: Wall::BOTTOM + 14, angle: 90, angle_anchor_y: 0, color: :white)
      end

      def right_out
        Primitive.sprite(:light_beam, x: Wall::RIGHT - 7, y: Wall::BOTTOM + 15, angle: 270, angle_anchor_y: 0, color: :white)
      end
    end
  end
end
