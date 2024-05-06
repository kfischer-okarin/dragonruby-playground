def tick(args)
  args.outputs.primitives << [x_axis, y_axis]
end

AXIS_THICKNESS = 10

def x_axis
  origin = convert_coordinates(0, 0)
  end_point = convert_coordinates(1, 0)
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
  origin = convert_coordinates(0, 0)
  end_point = convert_coordinates(0, 1)
  {
    x: origin[:x] - AXIS_THICKNESS,
    y: origin[:y],
    w: AXIS_THICKNESS,
    h: end_point[:y] - origin[:y],
    path: :pixel,
    r: 0, g: 0, b: 0
  }
end

def convert_coordinates(x, y)
  {
    x: 320 + x * 640,
    y: 40 + y * 640
  }
end
