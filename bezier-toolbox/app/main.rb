def tick(args)
  args.state.options ||= {
    show_bezier: true
  }
  args.state.drag ||= { state: :not_dragging }
  args.state.dr_spline_points ||= [
    { x: 0, y: 0 },
    { x: 1/3, y: 0.25 },
    { x: 2/3, y: 0.25 },
    { x: 1, y: 1 }
  ]
  args.state.bezier_point1 ||= { x: 0.25, y: 0.1 }
  args.state.bezier_point2 ||= { x: 0.25, y: 1 }

  handle_dragging(args)
  args.state.dr_spline_points.each_with_index do |point, index|
    point[:x] = index / 3
  end
  handle_options(args)

  args.outputs.primitives << [x_axis, y_axis]
  red = { r: 200, g: 0, b: 0 }
  if args.state.options[:show_bezier]
    args.outputs.primitives << cubic_bezier_curve(args.state.bezier_point1, args.state.bezier_point2, color: red)
    args.outputs.primitives << render_line({ x: 0, y: 0 }, args.state.bezier_point1, color: red)
    args.outputs.primitives << render_point(args.state.bezier_point1, color: red)
    args.outputs.primitives << render_point_label(args.state.bezier_point1, color: red)
    args.outputs.primitives << render_line({ x: 1, y: 1 }, args.state.bezier_point2, color: red)
    args.outputs.primitives << render_point(args.state.bezier_point2, color: red)
    args.outputs.primitives << render_point_label(args.state.bezier_point2, color: red)
  end

  blue = { r: 0, g: 0, b: 255 }
  args.outputs.primitives << dr_bezier_curve(
    args.state.dr_spline_points,
    color: blue
  )
  args.outputs.primitives << render_line({ x: 0, y: 0 }, args.state.dr_spline_points[1], color: blue)
  args.outputs.primitives << render_point(args.state.dr_spline_points[1], color: blue)
  args.outputs.primitives << render_point_label(args.state.dr_spline_points[1], color: blue)
  args.outputs.primitives << render_line({ x: 1, y: 1 }, args.state.dr_spline_points[2], color: blue)
  args.outputs.primitives << render_point(args.state.dr_spline_points[2], color: blue)
  args.outputs.primitives << render_point_label(args.state.dr_spline_points[2], color: blue)

  render_ease_spline_code(args)
  args.outputs.labels << {
    x: 1260, y: 700,
    text: 'b: toggle cubic bezier',
    **red,
    alignment_enum: 2
  }
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
      rect: point_rect(point)
    }
  end

  if args.state.options[:show_bezier]
    result << {
      point: args.state.bezier_point1,
      rect: point_rect(args.state.bezier_point1)
    }
    result << {
      point: args.state.bezier_point2,
      rect: point_rect(args.state.bezier_point2)
    }
  end

  result
end

def handle_options(args)
  keyboard = args.inputs.keyboard
  options = args.state.options
  options[:show_bezier] = !options[:show_bezier] if keyboard.key_down.b
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
  blue = { r: 0, g: 0, b: 255 }
  args.outputs.labels << {
    x: 600, y: 400,
    text: 'args.easing.ease_spline(start_tick, current_tick, duration, [',
    **blue
  }
  y = 375
  spline.each do |segment|
    formatted_segment = '[' + segment.map { |y| '%0.2f' % y }.join(', ') + ']'
    args.outputs.labels << {
      x: 620, y: y,
      text: formatted_segment,
      **blue
    }
    y -= 25
  end
  args.outputs.labels << {
    x: 600, y: y,
    text: '])',
    **blue
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
      **spline_points[index..index + 2].map(&:y),
    ]
    index += 3
  end
  result
end

def cubic_bezier_curve(point1, point2, color: nil)
  resolution = 100
  start_point = { x: 0, y: 0 }
  end_point = { x: 1, y: 1 }
  last_point = start_point
  result = []
  resolution.times do |i|
    t = i / resolution
    s = 1 - t
    factor1 = s**3
    factor2 = 3 * s**2 * t
    factor3 = 3 * s * t**2
    factor4 = t**3
    x = (factor1 * start_point[:x]) + (factor2 * point1[:x]) + (factor3 * point2[:x]) + (factor4 * end_point[:x])
    y = (factor1 * start_point[:y]) + (factor2 * point1[:y]) + (factor3 * point2[:y]) + (factor4 * end_point[:y])
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

def render_point_label(point, color: nil)
  converted_point = convert_coordinates(point)
  y_offset = point[:y] > 0.5 ? -10 : 25
  {
    x: converted_point[:x],
    y: converted_point[:y] + y_offset,
    text: '(%0.2f, %0.2f)' % [point[:x], point[:y]],
    size_enum: -2,
    alignment_enum: 1,
    **(color || { r: 0, g: 0, b: 0 })
  }
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
