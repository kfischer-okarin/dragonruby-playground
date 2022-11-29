class Sprite3D < Resources::Sprite
  attr_reader :z

  def z=(value)
    camera_distance = 400
    distance = camera_distance - value
    @z_factor = distance / camera_distance
    @z = value
  end

  def w
    @w * @z_factor
  end

  def h
    @h * @z_factor
  end
end
