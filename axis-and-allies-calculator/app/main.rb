require 'lib/big_integer'
require 'lib/fraction'
require 'tests'

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
  setup(args) if args.state.tick_count == 0

  handle_input(args)

  render_units(args)
  render_rounds(args)
  render_buttons(args)
  render_projections(args)
end

def setup(args)
  args.state.simulated_rounds = 1
  args.state.attackers = {}
  args.state.defenders = {}
  args.state.attacker_hit_count_ps = { 0 => Fraction[1] }
  args.state.defender_hit_count_ps = { 0 => Fraction[1] }
  args.state.result_ps = {}
  args.state.buttons = build_buttons(args)
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

  result = UNITS.keys.each_with_index.flat_map { |unit, index|
    y = 625 - index * 40
    [
      {
        x: ATTACKER_X - 50, y: y, w: 30, h: 30, type: :remove,
        on_click: -> { change_unit_count(args, attackers, unit, -1) }
      },
      {
        x: ATTACKER_X + 20, y: y, w: 30, h: 30, type: :add,
        on_click: -> { change_unit_count(args, attackers, unit, 1) }
      },
      {
        x: DEFENDER_X - 50, y: y, w: 30, h: 30, type: :remove,
        on_click: -> { change_unit_count(args, defenders, unit, -1) }
      },
      {
        x: DEFENDER_X + 20, y: y, w: 30, h: 30, type: :add,
        on_click: -> { change_unit_count(args, defenders, unit, 1) }
      }
    ]
  }

  result << {
    x: ATTACKER_X - 50, y: 15, w: 30, h: 30, type: :remove,
    on_click: -> { update_simulated_rounds(args, -1) }
  }
  result << {
    x: ATTACKER_X + 20, y: 15, w: 30, h: 30, type: :add,
    on_click: -> { update_simulated_rounds(args, 1) }
  }
  result
end

def change_unit_count(args, group, unit, delta)
  group[unit] = [(group[unit] || 0) + delta, 0].max
  group.delete(unit) if group[unit] == 0
  update_projections(args)
end

def update_simulated_rounds(args, delta)
  args.state.simulated_rounds = [args.state.simulated_rounds + delta, 1].max
  update_projections(args)
end

def unit_list(unit_group)
  unit_group.flat_map { |unit, count| [unit] * count }
end

def unit_count(unit_group)
  unit_group.values.sum
end

def remove_attacker_casualties(group, hits)
  remove_casualties(group, hits, :attack)
end

def remove_defender_casualties(group, hits)
  remove_casualties(group, hits, :defense)
end

def remove_casualties(group, hits, attribute)
  result = group.dup
  units = unit_list(group).sort_by { |unit|
    [UNITS[unit][attribute], UNITS[unit][:cost]]
  }
  hits.times do
    break if units.empty?

    unit = units.shift
    result[unit] -= 1
    result.delete(unit) if result[unit] == 0
  end
  result
end

def update_projections(args)
  args.state.attacker_hit_count_ps = calc_hit_count_ps(args.state.attackers, :attack)
  args.state.defender_hit_count_ps = calc_hit_count_ps(args.state.defenders, :defense)

  calc_result_ps(args)
end

def calc_hit_count_ps(unit_group, attribute)
  unit_list = unit_list(unit_group)
  single_hit_count_ps = unit_list.map { |unit|
    win_p = Fraction[UNITS[unit][attribute], 6]
    { 1 => win_p, 0 => Fraction[1] - win_p }
  }
  single_hit_count_ps.reduce({ 0 => Fraction[1] }) { |acc, ps|
    combine_hit_count_ps(acc, ps)
  }
end

def combine_hit_count_ps(ps1, ps2)
  result = {}
  ps1.each do |hits1, p1|
    ps2.each do |hits2, p2|
      hits = hits1 + hits2
      result[hits] = (result[hits] || Fraction[0]) + p1 * p2
    end
  end
  result
end

def calc_result_ps(args)
  result_state_ps = { [args.state.attackers, args.state.defenders] => Fraction[1] }
  args.state.simulated_rounds.times do
    result_state_ps = round_ps(calc_next_round_ps(result_state_ps), 10000)
  end
  args.state.result_state_ps = result_state_ps

  win_p = Fraction[0]
  lose_p = Fraction[0]
  result_state_ps.each do |((attackers, defenders), p)|
    if !attackers.empty? && defenders.empty?
      win_p += p
    end
    if attackers.empty?
      lose_p += p
    end
  end
  args.state.win_p = win_p
  args.state.lose_p = lose_p
end

def calc_next_round_ps(round_ps)
  result = {}
  round_ps.each do |(attackers, defenders), p|
    if attackers.empty? || defenders.empty?
      result[[attackers, defenders]] = (result[[attackers, defenders]] || Fraction[0]) + p
      next
    end

    attacker_hit_count_ps = calc_hit_count_ps(attackers, :attack)
    defender_hit_count_ps = calc_hit_count_ps(defenders, :defense)
    attacker_hit_count_ps.each do |defender_casualties, attacker_p|
      defender_hit_count_ps.each do |attacker_casualties, defender_p|
        next_round_attackers = remove_attacker_casualties(attackers, attacker_casualties)
        next_round_defenders = remove_defender_casualties(defenders, defender_casualties)
        next_round = [next_round_attackers, next_round_defenders]
        result[next_round] = (result[next_round] || Fraction[0]) + attacker_p * defender_p * p
      end
    end
  end
  result
end

def round_ps(ps, denominator)
  values = []
  ps.each do |key, p|
    values << [key, Fraction[(p.to_f * denominator).round, denominator]]
  end
  sum_except_last = Fraction[0]
  values[0..-2].each do |_, p|
    sum_except_last += p
  end
  values[-1][1] = Fraction[1] - sum_except_last
  values.to_h
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

def render_rounds(args)
  args.outputs.labels << { x: 20, y: 40, text: 'Simulated Rounds' }
  args.outputs.labels << { x: ATTACKER_X, y: 40, text: args.state.simulated_rounds, anchor_x: 0.5 }
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

def render_projections(args)
  render_hit_count_ps(
    args,
    args.state.attacker_hit_count_ps,
    x: 640,
    y: 600,
    title: 'Attacker Hit Count',
    color: { r: 255, g: 0, b: 0 }
  )

  render_hit_count_ps(
    args,
    args.state.defender_hit_count_ps,
    x: 640,
    y: 450,
    title: 'Defender Hit Count',
    color: { r: 0, g: 0, b: 255 }
  )

  args.outputs.labels << { x: 640, y: 400, text: "Win Probability: #{args.state.win_p.to_f}" }
  args.outputs.labels << { x: 640, y: 350, text: "Lose Probability: #{args.state.lose_p.to_f}" }
end

def render_hit_count_ps(args, hit_count_ps, x:, y:, title:, color:)
  w = 500
  h = 100
  bar_count = hit_count_ps.size
  bar_w = w / (bar_count + 1)
  args.outputs.lines << { x: x, y: y, x2: x + w, y2: y }
  args.outputs.lines << { x: x, y: y, x2: x, y2: y + h }
  bar_count.times do |hit_count|
    p = hit_count_ps[hit_count] || Fraction[0]
    bar_h = p.to_f * h
    bar_x = x + bar_w * (hit_count + 1) - bar_w / 2
    args.outputs.sprites << {
      x: bar_x,
      y: y,
      w: bar_w,
      h: bar_h,
      path: :pixel,
      **color
    }
    args.outputs.labels << {
      x: bar_x + bar_w / 2,
      y: y - 5,
      text: hit_count,
    }
  end
end

def unit_name(unit_symbol)
  unit_symbol.to_s.split('_').map(&:capitalize).join(' ')
end
