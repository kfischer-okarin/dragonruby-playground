class FrequencyMeter
  class MeterLayout
    def initialize(left_positions)
      @positions = left_positions + left_positions.reverse_each.map { |pos| [left_positions[-1].x * 2 - pos.x + 1, pos.y] }
    end

    def knob_offset(sonic_gun)
      step_size = (sonic_gun.max_frequency - sonic_gun.min_frequency) / @positions.size
      step_index = (sonic_gun.frequency - sonic_gun.min_frequency) / step_size
      @positions[step_index].dup
    end
  end

  def initialize(values)
    @x = values[:x]
    @y = values[:y]
    @sonic_gun = values.delete(:sonic_gun)
    @meter = Resources.sprites.frequency_meter.path
    @knob = Resources.sprites.frequency_knob.path
    refresh
  end

  LEFT_POSITIONS = [
    [2, -3],
    [3, -2],
    [4, -1],
    [5, 0],
    [6, 1],
    [7, 2],
    [8, 2],
    [9, 3],
    [10, 3],
    [11, 3],
    [12, 3],
    [13, 4],
    [14, 4],
    [15, 4],
    [16, 4],
    [17, 5],
    [18, 5],
    [19, 5],
    [20, 5],
    [21, 5],
    [22, 6],
    [23, 6],
    [24, 6],
    [25, 6],
    [26, 6],
    [27, 6],
    [28, 6],
    [29, 6]
  ].freeze

  FULL_LAYOUT = MeterLayout.new LEFT_POSITIONS

  def refresh
    @knob_offset_x, @knob_offset_y = FULL_LAYOUT.knob_offset(@sonic_gun)
  end

  def primitive_marker
    :sprite
  end

  def draw_override(ffi_draw)
    ffi_draw.draw_sprite @x, @y, 64, 16, @meter
    ffi_draw.draw_sprite @x + @knob_offset_x, @y + @knob_offset_y, 5, 6, @knob
  end

  private

  def positions
    @positions ||= LEFT_POSITIONS + LEFT_POSITIONS.map { |pos| [58 - pos.x, pos.y] }
  end

  def steps
    @steps ||= positions.size
  end
end
