module ComposableSoundGenerator
  def +(other)
    result = lambda do |t|
      call(t) + other.call(t)
    end
    result.extend ComposableSoundGenerator
    result
  end

  def *(other)
    result = lambda do |t|
      call(t) * other.call(t)
    end
    result.extend ComposableSoundGenerator
    result
  end
end

def sin_osc(frequency)
  result = lambda do |t|
    Math.sin(t * frequency * Math::PI * 2) * 0.5
  end
  result.extend ComposableSoundGenerator
  result
end

def line(start_value, end_value, duration)
  result = lambda do |t|
    t < duration ? start_value : end_value
  end
  result.extend ComposableSoundGenerator
  result
end

