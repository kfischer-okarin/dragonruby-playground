def tick(args)
  args.state.grid ||= initial_grid
  args.state.background_color ||= { r: 0, g: 0, b: 0 }
  args.state.text_color ||= { r: 255, g: 255, b: 255 }

  args.outputs.background_color = [args.state.background_color[:r], args.state.background_color[:g], args.state.background_color[:b]]

  unless args.state.game_setup_complete
    setup_game(args)
    return
  end
  tiles = build_tiles(args.state.grid)
  tiles.each do |tile|
    handle_animation(args, tile)

    draw_tile(args, tile)
  end

  if args.state.picture_downloaded
    args.outputs.primitives << {
      x: 100,
      y: 300,
      w: 320,
      h: 320,
      path: 'board_picture.jpg'
    }.sprite!
    args.outputs.primitives << {
      x: 100, y: 280, text: 'Press N to play with numbers instead',
    }.label!(args.state.text_color)
  end

  args.outputs.primitives << {
    x: 100, y: 260, text: 'Press B to change background color',
  }.label!(args.state.text_color)
  args.outputs.primitives << {
    x: 100, y: 240, text: 'Press R to reset',
  }.label!(args.state.text_color)

  mouse = args.inputs.mouse
  key_down = args.inputs.keyboard.key_down
  if args.state.game_won
    args.outputs.primitives << {
      x: 300,
      y: 260,
      w: 680,
      h: 200,
      path: :pixel,
      r: 0,
      g: 0,
      b: 0,
      a: 200
    }.solid!
    args.outputs.primitives << {
      x: 640, y: 360, text: 'You won!',
      alignment_enum: 1, vertical_alignment_enum: 1, size_enum: 60,
      r: 255, g: 255, b: 255
    }.label!
  elsif !args.state.slide_animation
    movable_tiles = tiles.select { |tile| tile[:movable_to] }
    if mouse.click
      clicked_tile = movable_tiles.find { |tile| mouse.point.inside_rect? tile }
      start_slide_animation(args, clicked_tile) if clicked_tile
    else
      keyboard_moved_tile = movable_tiles.find { |tile| key_down.send(tile[:movable_to][:direction]) }
      start_slide_animation(args, keyboard_moved_tile) if keyboard_moved_tile
    end
  end

  if key_down.b
    args.state.background_color = invert_color(args.state.background_color)
    args.state.text_color = invert_color(args.state.text_color)
  end
  if args.state.picture_downloaded && key_down.n
    args.state.picture_downloaded = false
  end
  $gtk.reset seed: Time.now.to_f * 1000 if key_down.r
end

COLORS = [
  { r: 255, g: 209, b: 220 },
  { r: 255, g: 221, b: 202 },
  { r: 255, g: 240, b: 219 },
  { r: 255, g: 228, b: 196 },
  { r: 255, g: 218, b: 233 },
  { r: 221, g: 235, b: 247 },
  { r: 207, g: 226, b: 243 },
  { r: 197, g: 225, b: 165 },
  { r: 255, g: 246, b: 143 },
  { r: 255, g: 214, b: 153 },
  { r: 255, g: 204, b: 188 },
  { r: 255, g: 204, b: 204 },
  { r: 204, g: 204, b: 255 },
  { r: 221, g: 214, b: 243 },
  { r: 255, g: 240, b: 245 }
]

def initial_grid
  [
    [ 1,  2,  3,   4],
    [ 5,  6,  7,   8],
    [ 9, 10, 11,  12],
    [13, 14, 15, nil]
  ].reverse # Reverse to start y from the bottom
   .transpose # Transpose to be able to access it via [x][y] instead of [y][x]
end

def setup_game(args)
  unless args.state.board_setup_complete
    # Do 100 random moves to shuffle the grid
    100.times do
      tiles = build_tiles(args.state.grid)
      movable_tiles = tiles.select { |tile| tile[:movable_to] }
      moved_tile = movable_tiles.sample
      swap_tile(args.state.grid, moved_tile[:grid_position], moved_tile[:movable_to])
    end
    args.state.board_setup_complete = true
  end

  unless args.state.picture_setup_complete
    args.state.picture_request ||= $gtk.http_get('https://picsum.photos/640')
    if args.state.picture_request[:complete]
      if args.state.picture_request[:http_response_code] == 200
        $gtk.write_file('board_picture.jpg', args.state.picture_request[:response_data])
        $gtk.reset_sprite 'board_picture.jpg'
        args.state.picture_downloaded = true
      else
        args.state.picture_downloaded = false
      end
      args.state.picture_setup_complete = true
    end
  end

  args.state.game_setup_complete = args.state.board_setup_complete && args.state.picture_setup_complete
  args.outputs.primitives << {
    x: 640, y: 360, text: 'Loading...', alignment_enum: 1, vertical_alignment_enum: 1, size_enum: 60
  }.label!(args.state.text_color)
end

def build_tiles(grid)
  tiles = []

  grid.each_with_index do |column, x|
    column.each_with_index do |number, y|
      next unless number

      tiles << tile_rect(x, y).merge(
        number: number,
        grid_position: { x: x, y: y },
        movable_to: movable_direction(grid, x, y)
      )
    end
  end

  tiles
end

def handle_animation(args, tile)
  if args.state.slide_animation && args.state.slide_animation[:number] == tile[:number]
    animation = args.state.slide_animation
    duration = 10
    t = (args.state.tick_count - animation[:start_time]) / duration

    tile[:x] = animation[:from_x].lerp(animation[:to_x], t)
    tile[:y] = animation[:from_y].lerp(animation[:to_y], t)

    if t >= 1
      args.state.slide_animation = nil
      swap_tile(args.state.grid, tile[:grid_position], tile[:movable_to])
      args.state.game_won = args.state.grid == initial_grid
    end
  end
end

def draw_tile(args, tile)
  if args.state.picture_downloaded
    grid_x = (tile[:number] - 1) % 4
    grid_y = (3 - (tile[:number] - 1).idiv(4))
    args.outputs.primitives << tile.to_sprite(
      path: 'board_picture.jpg',
      source_x: grid_x * tile[:w],
      source_y: grid_y * tile[:h],
      source_w: tile[:w],
      source_h: tile[:h]
    )
  else
    color = COLORS[tile[:number] - 1]
    args.outputs.primitives << tile.to_sprite(path: :pixel, **color)
    args.outputs.primitives << {
      x: tile[:x] + (tile[:w] / 2),
      y: tile[:y] + (tile[:h] / 2),
      text: tile[:number].to_s,
      alignment_enum: 1,
      vertical_alignment_enum: 1,
      size_enum: 30
    }
  end
end

def tile_rect(grid_x, grid_y)
  tile_size = 160
  offset_x = 200 + (1280 - (tile_size * 4)) / 2
  offset_y = (720 - (tile_size * 4)) / 2
  {
    x: offset_x + (tile_size * grid_x),
    y: offset_y + (tile_size * grid_y),
    w: tile_size,
    h: tile_size,
  }
end

def movable_direction(grid, x, y)
  if y < 3 && grid[x][y + 1].nil?
    { x: x, y: y + 1, direction: :up }
  elsif y > 0 && grid[x][y - 1].nil?
    { x: x, y: y - 1, direction: :down }
  elsif x > 0 && grid[x - 1][y].nil?
    { x: x - 1, y: y, direction: :left }
  elsif x < 3 && grid[x + 1][y].nil?
    { x: x + 1, y: y, direction: :right }
  end
end

def start_slide_animation(args, tile)
  target_position = tile_rect(tile[:movable_to][:x], tile[:movable_to][:y])
  args.state.slide_animation = {
    number: tile[:number],
    start_time: args.state.tick_count,
    from_x: tile[:x],
    from_y: tile[:y],
    to_x: target_position[:x],
    to_y: target_position[:y]
  }
end

def swap_tile(grid, old_position, new_position)
  old_x = old_position[:x]
  old_y = old_position[:y]
  new_x = new_position[:x]
  new_y = new_position[:y]
  grid[old_x][old_y], grid[new_x][new_y] = grid[new_x][new_y], grid[old_x][old_y]
end

def invert_color(color)
  { r: 255 - color[:r], g: 255 - color[:g], b: 255 - color[:b] }
end

$gtk.reset seed: Time.now.to_f * 1000
