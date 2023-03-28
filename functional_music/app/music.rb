module ComposableSoundGenerator
  def +(other)
    ComposableSoundGenerator.define do |t|
      call(t) + other.call(t)
    end
  end

  def *(other)
    case other
    when Numeric
      ComposableSoundGenerator.define do |t|
        call(t) * other
      end
    when Proc
      ComposableSoundGenerator.define do |t|
        call(t) * other.call(t)
      end
    end
  end

  def self.define(&block)
    result = lambda(&block)
    result.extend ComposableSoundGenerator
    result
  end
end

def mix(sound_generators)
  sound_generators.reduce { |mixed_so_far, generator| mixed_so_far + generator }
end

def sin_osc(frequency)
  ComposableSoundGenerator.define do |t|
    Math.sin(t * frequency * Math::PI * 2) * 0.5
  end
end

def line(start_value, end_value, duration)
  ComposableSoundGenerator.define do |t|
    t < duration ? start_value : end_value
  end
end

def perc(attack: 0.01, release: 1, level: 1, curve: -4)
  envelope([0, level, 0], [attack, release], curve)
end

def envelope(levels, durations, curve)
  t = 0
  segments = []
  levels.each_cons(2).zip(durations).each do |(from_level, to_level), duration|
    t_max = t + duration
    segments << {
      curve: interpolation_curve(t_min: t, t_max: t_max, out_min: from_level, out_max: to_level, curve: curve),
      t_max: t_max
    }
    t = t_max
  end

  ComposableSoundGenerator.define do |t|
    segment = segments.find { |s| t < s[:t_max] }

    segment ? segment[:curve].call(t) : levels.last
  end
end

def interpolation_curve(t_min: 0, t_max: 1, out_min: 0.0, out_max: 1.0, curve: -4.0)
  t_change = t_max - t_min
  out_change = out_max - out_min
  case curve
  when -0.125..0.125 # use linear mapping if curve is close to zero
    ComposableSoundGenerator.define do |t|
      t = t.clamp(t_min, t_max)
      out_min + out_change * (t - t_min) / t_change
    end
  else
    grow = Math.exp(curve)
    a = out_change / (1 - grow)
    b = out_min + a
    ComposableSoundGenerator.define do |t|
      t = t.clamp(t_min, t_max)
      b - (a * (grow**(t - t_min)))
    end
  end
end

def clip_silence(sound_generator, amp: 0.0001, time: 0.1)
  state = { phase: :sound, since: 0 }
  ComposableSoundGenerator.define do |t|
    return 0.0 if state[:silence_start] && t >= state[:silence_start]

    value = sound_generator.call(t)
    case state[:phase]
    when :sound
      if value < amp
        state[:phase] = :quiet
        state[:since] = t
      end
      value
    when :quiet
      if value >= amp
        state[:phase] = :sound
        return value
      end
      if t - state[:since] >= time
        state[:silence_start] = t
        return 0.0
      end
      value
    end
  end
end
