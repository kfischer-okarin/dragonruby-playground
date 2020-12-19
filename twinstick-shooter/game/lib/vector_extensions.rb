module ArrayVectorExtensions
  def add_vector(other)
    [value(0) + other.x, value(1) + other.y]
  end
end

Array.include ArrayVectorExtensions
