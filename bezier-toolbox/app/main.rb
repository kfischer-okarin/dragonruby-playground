RED = { r: 200, g: 0, b: 0 }
BLUE = { r: 0, g: 0, b: 255 }

def tick(args)
  args.state.options ||= {
    show_bezier: true
  }
  args.state.drag ||= { state: :not_dragging }
  args.state.dr_spline_points ||= [
    { x: 0, y: 0 },
    { x: 0, y: 0.25 },
    { x: 0, y: 0.25 },
    { x: 0, y: 1 }
  ]
  args.state.bezier_points ||= [
    { x: 0, y: 0 },
    { x: 0.25, y: 0.1 },
    { x: 0.25, y: 1 },
    { x: 1, y: 1 }
  ]

  handle_dragging(args)
  fix_dr_bezier_points_x(args)
  handle_controls(args)

  args.outputs.primitives << [x_axis, y_axis]
  if args.state.options[:show_bezier]
    args.outputs.primitives << cubic_bezier_curve(args.state.bezier_points, color: RED)
    args.outputs.primitives << render_spline_points(args.state.bezier_points, color: RED)
    render_bezier_points(args)
  end

  args.outputs.primitives << dr_bezier_curve(
    args.state.dr_spline_points,
    color: BLUE
  )
  args.outputs.primitives << render_spline_points(args.state.dr_spline_points, color: BLUE)
  if args.state.drag[:handle]
     handle = args.state.drag[:handle]
     args.outputs.primitives << point_label(handle[:point], color: handle[:color])
  end

  render_ease_spline_code(args)
  label_x = 1030
  args.outputs.labels << {
    x: label_x, y: 700,
    text: 'b: toggle cubic bezier',
    **RED
  }
  args.outputs.labels << {
    x: label_x, y: 675,
    text: '+: add spline segment',
    **BLUE
  }
  if args.state.dr_spline_points.length > 4
    args.outputs.labels << {
      x: label_x, y: 650,
      text: '-: remove spline segment',
      **BLUE
    }
  end
  args.outputs.debug.watch $gtk.current_framerate.to_i.to_s
end

def handle_dragging(args)
  mouse = args.inputs.mouse
  handles = control_point_handles(args)
  case args.state.drag[:state]
  when :not_dragging
    if mouse.button_left
      hovered_handle = handles.find { |handle| mouse.inside_rect? handle[:rect] }
      if hovered_handle
        args.state.drag = {
          state: :dragging,
          handle: hovered_handle,
          start: { x: mouse.x, y: mouse.y },
          point_start: hovered_handle[:point].dup
        }
      end
    end
  when :dragging
    if mouse.button_left
      point = args.state.drag[:handle][:point]
      diff_x = (mouse.x - args.state.drag[:start][:x]) / RENDER_SCALE
      diff_y = (mouse.y - args.state.drag[:start][:y]) / RENDER_SCALE
      point[:x] = args.state.drag[:point_start][:x] + diff_x
      point[:y] = args.state.drag[:point_start][:y] + diff_y
    else
      args.state.drag = { state: :not_dragging }
    end
  end
end

def control_point_handles(args)
  result = []
  args.state.dr_spline_points.each do |point|
    result << {
      point: point,
      rect: point_rect(point),
      color: BLUE
    }
  end

  if args.state.options[:show_bezier]
    args.state.bezier_points.each do |point|
      result << {
        point: point,
        rect: point_rect(point),
        color: RED
      }
    end
  end

  result
end

def fix_dr_bezier_points_x(args)
  args.state.dr_spline_points.each_with_index do |point, i|
    point[:x] = i / (args.state.dr_spline_points.length - 1)
  end
end

def handle_controls(args)
  keyboard = args.inputs.keyboard
  options = args.state.options
  options[:show_bezier] = !options[:show_bezier] if keyboard.key_down.b
  add_spline_segment(args) if keyboard.key_down.plus
  remove_spline_segment(args) if keyboard.key_down.minus && args.state.dr_spline_points.length > 4
end

def add_spline_segment(args)
  spline_points = args.state.dr_spline_points
  second_to_last_point = spline_points[-2]
  3.times do
    spline_points.insert(
      -2,
      {
        x: 0,
        y: second_to_last_point[:y]
      }
    )
  end
end

def remove_spline_segment(args)
  3.times { args.state.dr_spline_points.delete_at(-2) }
end

def dr_bezier_curve(spline_points, color: nil)
  resolution = 100
  start_point = { x: 0, y: 0 }
  last_point = start_point
  result = []
  spline = dr_spline_points_to_easing_spline(spline_points)
  resolution.times do |i|
    t = i / resolution
    y = $args.easing.ease_spline(0, i, resolution, spline)
    converted_next_point = convert_coordinates(x: t, y: y)

    result << {
      **convert_coordinates(last_point),
      x2: converted_next_point[:x],
      y2: converted_next_point[:y],
      **(color || { r: 0, g: 0, b: 0 })
    }
    last_point = { x: t, y: y }
  end
  result
end

def render_ease_spline_code(args)
  spline = dr_spline_points_to_easing_spline(args.state.dr_spline_points)
  args.outputs.labels << {
    x: 600, y: 400,
    text: 'args.easing.ease_spline(start_tick, current_tick, duration, [',
    **BLUE
  }
  y = 375
  spline.each do |segment|
    formatted_segment = '[' + segment.map { |y| '%0.2f' % y }.join(', ') + ']'
    args.outputs.labels << {
      x: 620, y: y,
      text: formatted_segment,
      **BLUE
    }
    y -= 25
  end
  args.outputs.labels << {
    x: 600, y: y,
    text: '])',
    **BLUE
  }
end

def dr_spline_points_to_easing_spline(spline_points)
  result = [
    spline_points[0..3].map(&:y)
  ]
  index = 4
  while index < spline_points.length
    previous_spline = result[-1]
    result << [
      previous_spline[3],
      *spline_points[index..index + 2].map(&:y),
    ]
    index += 3
  end
  result
end

def render_spline_points(spline_points, color: nil)
  result = []
  spline_points.each_with_index do |point, index|
    result << render_point(point, color: color)
    if (index - 1) % 3 == 0
      result << render_line(spline_points[index - 1], point, color: color)
    elsif (index - 1) % 3 == 1
      result << render_line(point, spline_points[index + 1], color: color)
    end
  end
  result
end

def cubic_bezier_curve(bezier_points, color: nil)
  resolution = 100
  last_point = bezier_points[0]
  result = []
  resolution.times do |i|
    t = i / resolution
    s = 1 - t
    factors = [s**3, 3 * s**2 * t, 3 * s * t**2, t**3]
    x = factors.zip(bezier_points.map(&:x)).map { |(factor, x)| factor * x }.sum
    y = factors.zip(bezier_points.map(&:y)).map { |(factor, y)| factor * y }.sum
    converted_next_point = convert_coordinates(x: x, y: y)

    result << {
      **convert_coordinates(last_point),
      x2: converted_next_point[:x],
      y2: converted_next_point[:y],
      **(color || { r: 0, g: 0, b: 0 })
    }
    last_point = { x: x, y: y }
  end
  result
end

def render_bezier_points(args)
  args.outputs.primitives << {
    x: 600, y: 475,
    text: 'Cubic Bezier Control Points:',
    **RED
  }
  args.state.bezier_points.each_with_index do |point, i|
    args.outputs.primitives << {
      x: 600 + i * 140,
      y: 450,
      text: '(%0.2f, %0.2f)' % [point[:x], point[:y]],
      **RED
    }
  end
end

def point_label(point, color: nil)
  converted_point = convert_coordinates(point)
  y_offset = point[:y] > 0.5 ? -10 : 25
  [
    {
      x: converted_point[:x] - 50,
      y: converted_point[:y] + y_offset - 20,
      w: 100,
      h: 20,
      path: :pixel,
      r: 255, g: 255, b: 255
    },
    {
      x: converted_point[:x],
      y: converted_point[:y] + y_offset,
      text: '(%0.2f, %0.2f)' % [point[:x], point[:y]],
      size_enum: -2,
      alignment_enum: 1,
      **(color || { r: 0, g: 0, b: 0 })
    }
  ]
end

def render_line(start_point, end_point, color: nil)
  converted_start = convert_coordinates(start_point)
  converted_end = convert_coordinates(end_point)
  {
    x: converted_start[:x],
    y: converted_start[:y],
    x2: converted_end[:x],
    y2: converted_end[:y],
    **(color || { r: 0, g: 0, b: 0 })
  }
end

def render_point(point, color: nil)
  {
    **point_rect(point),
    path: :pixel,
    **(color || { r: 0, g: 0, b: 0 })
  }
end

def point_rect(point)
  converted_point = convert_coordinates(point)
  {
    x: converted_point[:x] - 5,
    y: converted_point[:y] - 5,
    w: 10,
    h: 10
  }
end

AXIS_THICKNESS = 10

def x_axis
  origin = convert_coordinates(x: 0, y: 0)
  end_point = convert_coordinates(x: 1, y: 0)
  {
    x: origin[:x],
    y: origin[:y] - AXIS_THICKNESS,
    w: end_point[:x] - origin[:x],
    h: AXIS_THICKNESS,
    path: :pixel,
    r: 0, g: 0, b: 0
  }
end

def y_axis
  origin = convert_coordinates(x: 0, y: 0)
  end_point = convert_coordinates(x: 0, y: 1)
  {
    x: origin[:x] - AXIS_THICKNESS,
    y: origin[:y],
    w: AXIS_THICKNESS,
    h: end_point[:y] - origin[:y],
    path: :pixel,
    r: 0, g: 0, b: 0
  }
end

RENDER_SCALE = 320
RENDER_ORIGIN_Y = (720 - RENDER_SCALE) / 2
RENDER_ORIGIN_X = RENDER_ORIGIN_Y

def convert_coordinates(point)
  {
    x: RENDER_ORIGIN_X + point[:x] * RENDER_SCALE,
    y: RENDER_ORIGIN_Y + point[:y] * RENDER_SCALE
  }
end
