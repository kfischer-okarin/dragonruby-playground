def tick(args)
  setup(args) if args.tick_count.zero?
  render(args)
  update(args)
  $gtk.reset if args.inputs.keyboard.key_down.r
end

def setup(args)
  args.state.mode = :edit_stage
  args.state.polygons = [
    [
      { x: 700, y: 0 },
      { x: 750, y: 200 },
      { x: 650, y: 400 },
      { x: 850, y: 400 },
      { x: 900, y: 200 },
      { x: 800, y: 0 }
    ],
    [
      { x: 500, y: 100 },
      { x: 680, y: 100 },
      { x: 680, y: 200 },
      { x: 500, y: 200 }
    ]
  ]
  args.state.walls = calc_walls(args)
  args.state.ball = { x: 100, y: 400, vx: 15, vy: 0, r: 20, state: :moving }
  args.state.collision_state = {}
end

def calc_walls(args)
  [].tap { |walls|
    stage_bounds = [
      { x: 0, y: 0 },
      { x: 1280, y: 0 },
      { x: 1280, y: 720 },
      { x: 0, y: 720 }
    ]
    [stage_bounds, *args.state.polygons].each do |polygon|
      each_polygon_line(polygon) do |start_point, end_point|
        walls << { x1: start_point.x, y1: start_point.y, x2: end_point.x, y2: end_point.y }
      end
    end
  }
end

def render(args)
  render_polygons(args)
  render_ball(args)
end

def render_polygons(args)
  args.state.polygons.each do |polygon|
    render_polygon(args, polygon, render_points: args.state.mode == :edit_stage)
  end
end

def render_polygon(args, polygon, render_points:)
  each_polygon_line(polygon) do |start_point, end_point|
    render_point(args, start_point) if render_points
    render_line(args, start_point, end_point)
  end
end

def each_polygon_line(polygon)
  polygon.size.times do |index|
    start_point = polygon[index]
    end_point = polygon[(index + 1) % polygon.size]
    yield start_point, end_point
  end
end

def render_point(args, point)
  args.outputs.primitives << {
    x: point.x - 5, y: point.y - 5, w: 10, h: 10, path: :pixel, r: 0, g: 0, b: 0
  }.sprite!
end

def render_line(args, start_point, end_point)
  args.outputs.primitives << {
    x: start_point.x, y: start_point.y, x2: end_point.x, y2: end_point.y, r: 0, g: 0, b: 0
  }.line!
end

def render_ball(args)
  ball = args.state.ball
  args.outputs.primitives << {
    x: ball.x - 20, y: ball.y - 20, w: 40, h: 40, path: 'sprites/circle.png'
  }.sprite!
  args.outputs.primitives << {
    x: 0, y: 720, text: $gtk.current_framerate.to_i.to_s
  }.label!
end

def update(args)
  update_ball(args) #if args.inputs.keyboard.key_down.space
end

def update_ball(args)
  friction_energy_loss = 0.99
  collision_energy_loss = 0.98
  ball = args.state.ball

  collision_state = args.state.collision_state
  collision_state.speed = speed = Math.sqrt(ball.vx**2 + ball.vy**2)
  collision_state.collisions = collisions = []
  if ball.state == :moving
    next_ball = { x: ball.x + ball.vx, y: ball.y + ball.vy, r: ball.r }
    collision_state.collided_walls = collided_walls = close_walls(args).select { |wall|
      collision = circle_line_collision(next_ball, wall)
      next false unless collision

      collisions << collision
      true
    }
  end

  if collisions.any?
    if speed < 0.2
      ball.vx = 0
      ball.vy = 0
      ball.state = :stopped
    else
      collision_state.velocity_angle = velocity_angle = Math.atan2(ball.vy, ball.vx)
      collision_state.wall_angle = wall_angle = calc_wall_angle(collided_walls)
      collision_state.collision_angle = collision_angle = wall_angle - velocity_angle
      collision_state.new_angle = new_angle = velocity_angle + collision_angle * 2
      ball.vx = speed * Math.cos(new_angle) * collision_energy_loss
      ball.vy = speed * Math.sin(new_angle) * collision_energy_loss
    end
  elsif ball.state == :moving
    ball.vy -= 0.1
    ball.vx *= friction_energy_loss
    ball.vy *= friction_energy_loss
  end

  ball.x += ball.vx
  ball.y += ball.vy
end

def calc_wall_angle(collided_walls)
  collided_wall = collided_walls[0]
  Math.atan2(
    collided_wall.y2 - collided_wall.y1,
    collided_wall.x2 - collided_wall.x1
  ) % Math::PI
  # TODO: Maybe handle several wall special cases?? but it seems to work now
end

def close_walls(args)
  args.state.walls
end

def circle_line_collision(ball, wall)
  if wall.x2 == wall.x1
    # circle equation:
    # (x - xc)**2 + (y - yc)**2 = r**2
    # => (x1 - xc)**2 + (y - yc)**2 = r**2
    # => (y - yc)**2 = r**2 - (x1 - xc)**2
    # => y = yc +- sqrt(r**2 - (x1 - xc)**2)

    in_sqrt = ball.r**2 - (wall.x1 - ball.x)**2
    return if in_sqrt.negative?

    sqrt_result = Math.sqrt(in_sqrt)
    y1 = ball.y + sqrt_result
    y2 = ball.y - sqrt_result
    wall_y_min, wall_y_max = [wall.y1, wall.y2].sort
    result = if y1 >= wall_y_min && y1 <= wall_y_max
               { x: wall.x1, y: y1 }
             elsif y2 >= wall_y_min && y2 <= wall_y_max
               { x: wall.x1, y: y2 }
             end
    return result
  end

  # circle equation:
  # (x - xc)**2 + (y - yc)**2 = r**2
  # line equation:
  # m = (y2 - y1) / (x2 - x1)
  # y = m * x + b
  # b = y - m * x

  # insert line equation into circle equation
  # => (x - xc)**2 + (m * x + b - yc)**2 = r**2
  # y_diff = b - yc
  # => (x - xc)**2 + (m * x + y_diff)**2 = r**2
  # => x**2 - 2 * xc * x + xc**2 + m**2 * x**2 + 2 * m * y_diff * x + y_diff**2 = r**2
  # => (1 + m**2) * x**2 + (2 * m * y_diff - 2 * xc) * x + (y_diff**2 + xc**2 - r**2) = 0
  # solve quadratic equation
  # p = (2 * m * y_diff - 2 * xc) / (1 + m**2)
  # q = (y_diff**2 + xc**2 - r**2) / (1 + m**2)
  # => x**2 + p * x + q = 0
  # => x = -p/2 +- sqrt(p**2 / 4 - q)
  m = (wall.y2 - wall.y1) / (wall.x2 - wall.x1)
  b = wall.y1 - m * wall.x1
  y_diff = b - ball.y
  p_value = (2 * m * y_diff - 2 * ball.x) / (1 + m**2)
  q = (y_diff**2 + ball.x**2 - ball.r**2) / (1 + m**2)

  in_sqrt = p_value**2 / 4 - q
  return if in_sqrt.negative?

  sqrt_result = Math.sqrt(in_sqrt)
  x1 = -(p_value / 2) + sqrt_result
  x2 = -(p_value / 2) - sqrt_result
  wall_x_min, wall_x_max = [wall.x1, wall.x2].sort

  if x1 >= wall_x_min && x1 <= wall_x_max
    { x: x1, y: m * x1 + b }
  elsif x2 >= wall_x_min && x2 <= wall_x_max
    { x: x2, y: m * x2 + b }
  end
end

$gtk.reset
