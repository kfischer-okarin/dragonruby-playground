def tick(args)
  setup(args) if args.tick_count.zero?

  handle_button_click(args)

  handle_inbox args, read_inbox! if args.tick_count.mod_zero? 10

  render_buttons(args)

  if args.state.waiting_for_upload
    args.outputs.primitives << big_centered_label("Waiting for Upload...", x: 640, y: 500)
  end
end

def setup(args)
  args.state.stored_data = read_stored_data
  args.state.waiting_for_upload = false
  args.state.buttons = [
    args.layout.rect(col: 6, row: 5, w: 4, h: 2).merge(label: 'Download', action: :download),
    args.layout.rect(col: 14, row: 5, w: 4, h: 2).merge(label: 'Upload', action: :upload)
  ]
end

def handle_button_click(args)
  mouse = args.inputs.mouse
  if mouse.click
    clicked_button = args.state.buttons.find { |button| mouse.inside_rect? button }
    if clicked_button
      case clicked_button[:action]
      when :upload
        puts 'Upload clicked'
        args.state.waiting_for_upload = true
        write_to_outbox('upload')
      when :download
        puts 'Download clicked'
        write_to_outbox("download,#{args.state.stored_data}")
      end
    end
  end
end

def handle_inbox(args, inbox)
  if args.state.waiting_for_upload
    return unless inbox

    case inbox['type']
    when 'file_upload'
      puts 'File upload received'
      args.state.stored_data = inbox['content']
      write_stored_data inbox['content']
      args.state.waiting_for_upload = false
    when 'upload_canceled'
      puts 'File upload canceled'
      args.state.waiting_for_upload = false
    end
  end
end

def render_buttons(args)
  args.state.buttons.each do |button|
    args.outputs.primitives << [
      button.to_border(r: 0, g: 0, b: 0),
      big_centered_label(button[:label], x: button.center_x, y: button.center_y)
    ]
  end
end

def write_to_outbox(value)
  $gtk.write_file('outbox', value)
end

def read_inbox!
  result = $gtk.read_file('inbox')
  if result
    result = $gtk.parse_json(result) if result&.start_with? '{'
    $gtk.delete_file('inbox')
  end
  result
end

def big_centered_label(text, x:, y:)
  {
    x: x, y: y, text: text, alignment_enum: 1, vertical_alignment_enum: 1, size_px: 40
  }
end

def read_stored_data
  $gtk.read_file('stored_data')
end

def write_stored_data(value)
  $gtk.write_file('stored_data', value)
end

$gtk.reset
