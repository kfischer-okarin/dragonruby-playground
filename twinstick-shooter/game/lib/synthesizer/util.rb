module Util
  class Params
    def self.[](value_hash)
      new(value_hash)
    end

    def initialize(value_hash)
      @value_hash = value_hash
      @permitted = []
    end

    def permit!(*keys)
      @permitted.concat(keys)
      unknown = @value_hash.keys.reject { |key| @permitted.include? key }
      raise "Unknown keyword arguments: #{unknown}" unless unknown.empty?

      self
    end

    def require!(*keys)
      @permitted.concat(keys)
      missing = keys.reject { |key| @value_hash.key? key }
      raise "Required keyword arguments missing: #{missing}" unless missing.empty?

      self
    end
  end

  class WaveformPlotter
    def initialize(args)
      Params[args].require!(:w, :h).permit!(:x, :y, :samples_per_pixel, :sample_offset, :max_amplitude)
      @x = args[:x] || 0
      @y = args[:y] || 0
      @w = args[:w]
      @h = args[:h]
      @max_amplitude = args[:max_amplitude] || 1
      @samples_per_pixel = args[:samples_per_pixel]
      @sample_offset = args[:sample_offset] || 0
      calc_y_scale
      calc_y_offset
    end

    def y=(value)
      @y = value
      calc_y_offset
    end

    def h=(value)
      @h = value
      calc_y_scale
      calc_y_offset
    end

    def max_amplitude=(value)
      @max_amplitude = value
      calc_y_scale
    end

    def plot(sound)
      samples_per_pixel = @samples_per_pixel || (sound.size / @w).floor
      [].tap { |result|
        last_point = nil
        @w.times do |x|
          current_point = [@x + x, sound[@offset + x * samples_per_pixel] * @y_scale + @y_offset]
          result << [last_point, current_point, 255, 0, 0].line if last_point
          last_point = current_point
        end
      }
    end

    private

    def calc_y_scale
      @y_scale = @h / (2 * @max_amplitude)
    end

    def calc_y_offset
      @y_offset = @y + @h.div(2)
    end
  end
end
