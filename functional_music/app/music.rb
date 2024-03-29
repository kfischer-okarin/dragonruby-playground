module ComposableAudioSource
  def +(other)
    ComposableAudioSource.define do |t|
      a = call(t)
      return a if a == :finish_audio

      b = other.call(t)
      return b if b == :finish_audio

      a + b
    end
  end

  def *(other)
    case other
    when Numeric
      ComposableAudioSource.define do |t|
        a = call(t)
        return a if a == :finish_audio

        a * other
      end
    when Proc
      ComposableAudioSource.define do |t|
        a = call(t)
        return a if a == :finish_audio

        b = other.call(t)
        return b if b == :finish_audio

        a * b
      end
    end
  end

  def self.define(&block)
    result = lambda(&block)
    result.extend ComposableAudioSource
    result
  end
end

def mix(sound_generators)
  sound_generators.reduce { |mixed_so_far, generator| mixed_so_far + generator }
end

def sin_osc(frequency)
  ComposableAudioSource.define do |t|
    Math.sin(t * frequency * Math::PI * 2) * 0.5
  end
end

def line(start_value, end_value, duration, finish_audio_when_done: false)
  value_range = end_value - start_value

  if finish_audio_when_done
    ComposableAudioSource.define do |t|
      if t < duration
        start_value + (value_range * (t / duration))
      else
        :finish_audio
      end
    end
  else
    ComposableAudioSource.define do |t|
      if t < duration
        start_value + (value_range * (t / duration))
      else
        end_value
      end
    end
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

  ComposableAudioSource.define do |t|
    segment = segments.find { |s| t < s[:t_max] }

    segment ? segment[:curve].call(t) : levels.last
  end
end

def interpolation_curve(t_min: 0, t_max: 1, out_min: 0.0, out_max: 1.0, curve: -4.0)
  t_change = t_max - t_min
  out_change = out_max - out_min
  case curve
  when -0.125..0.125 # use linear mapping if curve is close to zero
    ComposableAudioSource.define do |t|
      t = t.clamp(t_min, t_max)
      out_min + out_change * (t - t_min) / t_change
    end
  else
    grow = Math.exp(curve)
    a = out_change / (1 - grow)
    b = out_min + a
    ComposableAudioSource.define do |t|
      t = t.clamp(t_min, t_max)
      b - (a * (grow**(t - t_min)))
    end
  end
end

def clip_silence(sound_generator, amp: 0.0001, time: 0.1)
  state = { phase: :sound, since: 0 }
  ComposableAudioSource.define do |t|
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
