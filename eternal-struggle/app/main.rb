CENTER_X = 640
CENTER_Y = 360
CIRCLE_RADIUS = 300
BALL_RADIUS = CIRCLE_RADIUS.idiv(6)
BALL_V = 5
SIMULATION_STEPS = 5

def tick(args)
  setup(args) if Kernel.tick_count.zero?

  args.state.balls.each do |ball|
    SIMULATION_STEPS.times do
      next_x = ball[:x] + (ball[:dx] * BALL_V) / SIMULATION_STEPS
      next_y = ball[:y] + (ball[:dy] * BALL_V) / SIMULATION_STEPS

      ball[:x] = next_x
      ball[:y] = next_y
    end
  end

  render(args)
end

def setup(args)
  args.state.balls = [
    {
      x: CENTER_X, y: CENTER_Y + CIRCLE_RADIUS.half,
      dx: 0, dy: -1,
      radius: BALL_RADIUS,
      color: { r: 255, g: 255, b: 255 }
    },
    {
      x: CENTER_X, y: CENTER_Y - CIRCLE_RADIUS.half,
      dx: 0, dy: -1,
      radius: BALL_RADIUS,
      color: { r: 0, g: 0, b: 0 }
    }
  ]
  args.state.stage_points = build_stage_points
  args.state.wall_points = build_ying_yang_walls
  args.state.sprites = {
    circle: prepare_circle_sprite(args, radius: CIRCLE_RADIUS),
    ball: prepare_circle_sprite(args, radius: BALL_RADIUS)
  }
end

def build_stage_points
  (0..360).map { |angle|
    {
      x: CENTER_X + (ANGLE_COS[angle] * CIRCLE_RADIUS).round,
      y: CENTER_Y + (ANGLE_SIN[angle] * CIRCLE_RADIUS).round
    }
  }
end

def build_ying_yang_walls
  result = []

  radius = CIRCLE_RADIUS.half
  center_x = CENTER_X
  center_y = CENTER_Y - CIRCLE_RADIUS.half
  # 0 degrees is pointing right and 90 degrees is pointing up
  # so to get the lower half of the ying yang we go from 270 down to 90
  (90..270).reverse_each do |angle|
    result << {
      x: center_x + (ANGLE_COS[angle] * radius).round,
      y: center_y + (ANGLE_SIN[angle] * radius).round
    }
  end
  center_y = CENTER_Y + CIRCLE_RADIUS.half
  # to get the upper half of the ying yang we go from 270 to 450 (90 degrees past 360)
  (270..450).each do |angle|
    angle %= 360
    result << {
      x: center_x + (ANGLE_COS[angle] * radius).round,
      y: center_y + (ANGLE_SIN[angle] * radius).round
    }
  end

  result
end

def prepare_circle_sprite(args, radius:)
  diameter = radius * 2 + 1
  rt_name = :"circle#{radius}"
  rt = args.outputs[rt_name]
  rt.w = diameter
  rt.h = diameter
  rt.primitives << filled_circle(center_x: radius, center_y: radius, radius: radius, r: 255, g: 255, b: 255)
  {
    w: diameter,
    h: diameter,
    path: rt_name
  }
end

ANGLE_SIN = (0..360).map { |angle| Math.sin(angle.to_radians) }.freeze
ANGLE_COS = (0..360).map { |angle| Math.cos(angle.to_radians) }.freeze

def filled_circle(center_x:, center_y:, radius:, **triangle_args)
  (0..360).map { |angle|
    next_angle = (angle + 1) % 360
    {
      x: center_x + (ANGLE_COS[angle] * radius).round,
      y: center_y + (ANGLE_SIN[angle] * radius).round,
      x2: center_x + (ANGLE_COS[next_angle] * radius).round,
      y2: center_y + (ANGLE_SIN[next_angle] * radius).round,
      x3: center_x,
      y3: center_y,
      **triangle_args
    }
  }
end

def render(args)
  sprites = args.state.sprites
  args.outputs.sprites << sprites[:circle].merge(x: 340, y: 60, r: 255, g: 0, b: 0)
  args.state.balls.each do |ball|
    args.outputs.sprites << sprites[:ball].merge(
      x: ball[:x] - BALL_RADIUS,
      y: ball[:y] - BALL_RADIUS,
      **ball[:color]
    )
  end
  first_wall_point = args.state.wall_points.first
  args.state.wall_points[1..].each do |second_wall_point|
    args.outputs.primitives << {
      x: first_wall_point[:x],
      y: first_wall_point[:y] + 1,
      x2: second_wall_point[:x],
      y2: second_wall_point[:y] + 1,
      r: 0,
      g: 0,
      b: 0
    }
    first_wall_point = second_wall_point
  end

  args.outputs.debug << $gtk.current_framerate.to_s
end
