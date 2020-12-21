module ArrayVectorExtensions
  def zero?
    value(0).zero? && value(1).zero?
  end

  def diagonal?
    !value(0).zero? && !value(1).zero?
  end

  def add_vector(other)
    [value(0) + other.x, value(1) + other.y]
  end
end

Array.include ArrayVectorExtensions
