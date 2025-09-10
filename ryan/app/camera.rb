class Camera
  attr_accessor :perspective, :center

  def initialize(screen_center_x: 640, screen_center_y: 360, scale: 1, pitch: 20, yaw: 100)
    @center = { x: 0, y: 0 }
    @perspective = Perspective.new(scale: scale, pitch: pitch, yaw: yaw)
    @screen_center_x = screen_center_x
    @screen_center_y = screen_center_y
  end

  def transform_object(object)
    transformed = @perspective.transform_coordinates(
      x: object[:x] - @center[:x],
      y: object[:y] - @center[:y]
    )
    object.merge(
      x: @screen_center_x + transformed[:x],
      y: @screen_center_y + transformed[:y]
    )
  end

  def move_forward(distance)
    forward_vector = @perspective.unrotate_coordinates(x: 0, y: 1)
    @center[:x] += forward_vector[:x] * distance
    @center[:y] += forward_vector[:y] * distance
  end

  def move_right(distance)
    right_vector = @perspective.unrotate_coordinates(x: 1, y: 0)
    @center[:x] += right_vector[:x] * distance
    @center[:y] += right_vector[:y] * distance
  end

  class Perspective
    attr_reader :yaw, :pitch, :scale

    def initialize(yaw: 0, pitch: 30, scale: 1)
      # convert yaw to range -180..180
      @yaw = (yaw + 180) % 360 - 180
      @yaw_sin = Math.sin(@yaw.to_radians)
      @yaw_cos = Math.cos(@yaw.to_radians)
      @pitch = pitch.clamp(15, 90)
      @pitch_sin = Math.sin(@pitch.to_radians)
      @pitch_cos = Math.cos(@pitch.to_radians)
      @scale = [1, scale].max.to_i
    end

    def with(yaw: nil, pitch: nil, scale: nil)
      self.class.new(
        yaw: yaw || @yaw,
        pitch: pitch || @pitch,
        scale: scale || @scale
      )
    end

    def rotate_coordinates(x:, y:)
      {
        x: x * @yaw_cos - y * @yaw_sin,
        y: x * @yaw_sin + y * @yaw_cos
      }
    end

    def unrotate_coordinates(x:, y:)
      {
        x: x * @yaw_cos + y * @yaw_sin,
        y: -x * @yaw_sin + y * @yaw_cos
      }
    end

    def transform_coordinates(x:, y:, z: 0)
      rotated = rotate_coordinates(x: x, y: y)
      y = transform_y_distance(rotated[:y])
      y += transform_z_distance(z) if z != 0
      {
        x: transform_x_distance(rotated[:x]),
        y: y
      }
    end

    def transform_x_distance(x)
      x * @scale
    end

    def transform_y_distance(y)
      y * @scale * @pitch_sin
    end

    def transform_z_distance(z)
      z * @scale * @pitch_cos
    end
  end
end
