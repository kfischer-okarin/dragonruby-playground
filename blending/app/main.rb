SDL_BLEND_MODE_NAME = {
  0 => :none,
  1 => :blend,
  2 => :add,
  3 => :mod,
  4 => :mul
}

def tick(args)
  args.state.shapes ||= [
    { x: 100, y: 100, w: 200, h: 200, path: :pixel, blendmode_enum: 1 }.sprite!,
    { x: 100, y: 400, w: 200, h: 200, path: 'sprites/circle.png', blendmode_enum: 1, r: 128, g: 50, b: 50 }.sprite!,
    { x: 400, y: 400, w: 200, h: 200, path: 'sprites/circle.png', blendmode_enum: 1, r: 50, g: 128, b: 50 }.sprite!,
    { x: 700, y: 300, w: 300, h: 300, path: 'sprites/circle.png', blendmode_enum: 1 }.sprite!
  ]
  args.state.drag_state ||= { dragging: false }

  handle_drag(args)

  args.outputs.background_color = [130, 0, 150]
  render_target = args.outputs[:screen]
  args.state.shapes.each do |shape|
    render_target.primitives << shape
  end
  args.outputs.primitives << { x: 0, y: 0, w: 1280, h: 720, path: :screen }.sprite!
  args.state.shapes.each_with_index do |shape, index|
    args.outputs.primitives << {
      x: shape.x + (shape.w / 2), y: shape.y + (shape.h / 2) + 10,
      text: index.to_s, alignment_enum: 1, vertical_alignment_enum: 1,
      size_enum: -2
    }.label!

    blendmode_enum = shape[:blendmode_enum]
    name = SDL_BLEND_MODE_NAME[blendmode_enum]
    args.outputs.primitives << {
      x: shape.x + (shape.w / 2), y: shape.y + (shape.h / 2) - 10,
      text: "#{name} (#{blendmode_enum})", alignment_enum: 1, vertical_alignment_enum: 1,
      size_enum: -2
    }.label!
  end
  if args.state.selected_shape
    shape = args.state.selected_shape
    args.outputs.primitives << shape.to_border(r: 255, g: 255, b: 0)

    key_down = args.inputs.keyboard.key_down
    %i[zero one two three four].each_with_index do |key, index|
      shape[:blendmode_enum] = index if key_down.send(key)
    end
  end
end

def handle_drag(args)
  mouse = args.inputs.mouse
  if args.state.drag_state[:dragging]
    if mouse.button_left
      dragged_shape = args.state.drag_state[:shape]
      dragged_shape[:x] = mouse.x - args.state.drag_state[:drag_start_position][0] + args.state.drag_state[:original_position][0]
      dragged_shape[:y] = mouse.y - args.state.drag_state[:drag_start_position][1] + args.state.drag_state[:original_position][1]
    else
      args.state.drag_state = { dragging: false }
    end
  elsif mouse.down
    grabbed_shape = args.state.shapes.find { |shape| mouse.inside_rect?(shape) }
    if grabbed_shape
      args.state.drag_state = {
        dragging: true,
        shape: grabbed_shape,
        original_position: [grabbed_shape.x, grabbed_shape.y],
        drag_start_position: [mouse.x, mouse.y]
      }
    end
    args.state.selected_shape = grabbed_shape
  end
end

$gtk.reset
