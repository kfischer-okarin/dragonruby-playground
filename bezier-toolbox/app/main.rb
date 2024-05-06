def tick(args)
  args.state.drag ||= { state: :not_dragging }
  args.state.bezier_point1 ||= { x: 0.25, y: 0.1 }
  args.state.bezier_point2 ||= { x: 0.25, y: 1 }

  handle_dragging(args)

  args.outputs.primitives << [x_axis, y_axis]
  red = { r: 200, g: 0, b: 0 }
  args.outputs.primitives << cubic_bezier_curve(args.state.bezier_point1, args.state.bezier_point2, color: red)
  args.outputs.primitives << render_line({ x: 0, y: 0 }, args.state.bezier_point1, color: red)
  args.outputs.primitives << render_point(args.state.bezier_point1, color: red)
  args.outputs.primitives << render_point_label(args.state.bezier_point1, color: red)
  args.outputs.primitives << render_line({ x: 1, y: 1 }, args.state.bezier_point2, color: red)
  args.outputs.primitives << render_point(args.state.bezier_point2, color: red)
  args.outputs.primitives << render_point_label(args.state.bezier_point2, color: red)
  args.outputs.debug.watch $gtk.current_framerate.to_i.to_s
end

def handle_dragging(args)
  mouse = args.inputs.mouse
  handles = control_point_handles(args)
  case args.state.drag[:state]
  when :not_dragging
    if mouse.button_left
      hovered_point_id = handles.keys.find { |key| mouse.inside_rect? handles[key] }
      if hovered_point_id
        args.state.drag = {
          state: :dragging,
          point_id: hovered_point_id,
          start: { x: mouse.x, y: mouse.y },
          point_start: args.state.send(hovered_point_id).dup
        }
      end
    end
  when :dragging
    if mouse.button_left
      point = args.state.send(args.state.drag[:point_id])
      diff_x = (mouse.x - args.state.drag[:start][:x]) / 640.0
      diff_y = (mouse.y - args.state.drag[:start][:y]) / 640.0
      point[:x] = args.state.drag[:point_start][:x] + diff_x
      point[:y] = args.state.drag[:point_start][:y] + diff_y
    else
      args.state.drag = { state: :not_dragging }
    end
  end
end

def control_point_handles(args)
  {
    bezier_point1: point_rect(args.state.bezier_point1),
    bezier_point2: point_rect(args.state.bezier_point2)
  }
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

def convert_coordinates(point)
  {
    x: 320 + point[:x] * 640,
    y: 40 + point[:y] * 640
  }
end
