require 'lib/fraction'

UNITS = {
  infantry: { attack: 1, defense: 2, cost: 3, movement: 1 },
  armor: { attack: 3, defense: 2, cost: 5, movement: 2 },
  fighter: { attack: 3, defense: 4, cost: 12, movement: 4 },
  bomber: { attack: 4, defense: 1, cost: 15, movement: 6 },
  antiaircraft: { attack: 0, defense: 1, cost: 5, movement: 1 },
  battleship: { attack: 4, defense: 4, cost: 24, movement: 2 },
  aircraft_carrier: { attack: 1, defense: 3, cost: 18, movement: 2 },
  transport: { attack: 0, defense: 1, cost: 8, movement: 2 },
  submarine: { attack: 2, defense: 2, cost: 8, movement: 2 }
}


def tick(args)
  args.state.attackers ||= {}
  args.state.defenders ||= {}
  args.state.buttons ||= build_buttons(args)

  handle_input(args)

  render_units(args)
  render_buttons(args)
end

ATTACKER_X = 280
DEFENDER_X = 430

def handle_input(args)
  mouse = args.inputs.mouse
  if mouse.click
    clicked_button = args.state.buttons.find { |button| mouse.inside_rect?(button) }
    clicked_button[:on_click].call if clicked_button
  end
end

def build_buttons(args)
  attackers = args.state.attackers
  defenders = args.state.defenders

  UNITS.keys.each_with_index.flat_map { |unit, index|
    y = 625 - index * 40
    [
      {
        x: ATTACKER_X - 50, y: y, w: 30, h: 30, type: :remove,
        on_click: -> { attackers[unit] = [attackers[unit] - 1, 0].max }
      },
      {
        x: ATTACKER_X + 20, y: y, w: 30, h: 30, type: :add,
        on_click: -> { attackers[unit] = (attackers[unit] || 0) + 1 }
      },
      {
        x: DEFENDER_X - 50, y: y, w: 30, h: 30, type: :remove,
        on_click: -> { defenders[unit] = [defenders[unit] - 1, 0].max }
      },
      {
        x: DEFENDER_X + 20, y: y, w: 30, h: 30, type: :add,
        on_click: -> { defenders[unit] = (defenders[unit] || 0) + 1 }
      }
    ]
  }
end

def render_units(args)
  unit_name_x = 20
  args.outputs.labels << { x: ATTACKER_X, y: 700, text: 'Attackers', anchor_x: 0.5 }
  args.outputs.labels << { x: DEFENDER_X, y: 700, text: 'Defenders', anchor_x: 0.5 }
  UNITS.each.with_index do |(unit, stats), i|
    label_y = 650 - i * 40
    line_y = 620 - i * 40
    args.outputs.labels << { x: unit_name_x, y: label_y, text: unit_name(unit) }
    attacker_count = args.state.attackers[unit] || 0
    args.outputs.labels << { x: ATTACKER_X, y: label_y, text: attacker_count, anchor_x: 0.5 }
    defender_count = args.state.defenders[unit] || 0
    args.outputs.labels << { x: DEFENDER_X, y: label_y, text: defender_count, anchor_x: 0.5 }
    args.outputs.lines << { x: unit_name_x, y: line_y, x2: DEFENDER_X + 50, y2: line_y }
  end
end

def render_buttons(args)
  args.outputs.primitives << args.state.buttons.map { |button|
    result = [
      button.merge(path: :pixel, r: 0, g: 0, b: 0)
    ]
    case button[:type]
    when :add
      result << { x: button[:x] + 7, y: button[:y] + 30, text: '+', size_enum: 5, r: 255, g: 255, b: 255 }
    when :remove
      result << { x: button[:x] + 7, y: button[:y] + 30, text: '-', size_enum: 5, r: 255, g: 255, b: 255 }
    end
    result
  }
end

def unit_name(unit_symbol)
  unit_symbol.to_s.split('_').map(&:capitalize).join(' ')
end
