require 'app/camera'

def tick(args)
  setup(args) if Kernel.tick_count.zero?
  args.outputs.background_color = { r: 0, g: 0, b: 0 }

  update_ryans(args)

  sprites = args.state.ryans.map { |ryan| ryan_sprite(ryan) }
  sprites.replace(sprites.sort_by { |sprite| -sprite[:y] })
  args.outputs.sprites << sprites

  # args.outputs.debug << "FPS: #{args.gtk.current_framerate}"
end

def setup(args)
  $camera = Camera.new(yaw: 40, pitch: 15)
  args.state.ryans = 20.times.flat_map { |row|
    30.times.map { |col|
      {
        x: -1500 + (col * 100) - 20 + rand(40),
        y: -1200 + (row * 200) - 10 + rand(20),
        z: 0,
        chef: rand < 0.1,
        jump_offset: rand(100),
        jump_speed: 0.1 + rand * 0.2
      }
    }
  }
end

def update_ryans(args)
  args.state.ryans.each do |ryan|
    ryan[:z] = Math.sin(args.tick_count * ryan[:jump_speed] + ryan[:jump_offset]) * 20
  end
end

def ryan_sprite(ryan)
  render_position = $camera.transform_object(x: ryan[:x], y: ryan[:y], z: ryan[:z])
  scale = 0.15 * (1 - (render_position[:y] - 360) / 720)
  w = (ryan[:chef] ? 852 : 799) * scale
  h = (ryan[:chef] ? 753 : 662) * scale
  {
    x: render_position[:x] - (w / 2),
    y: render_position[:y] + $camera.perspective.transform_z_distance(ryan[:z]),
    w: w,
    h: h,
    path: ryan[:chef] ? 'chef_ryan.png' : 'ryan.png'
  }
end

$gtk.reset
