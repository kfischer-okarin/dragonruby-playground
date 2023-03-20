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
