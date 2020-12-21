class SonicGun
  attr_reader :cooldown

  def initialize(values)
    @cooldown = values[:cooldown]
  end

  def create_bullet(entity)
    puts "SHOOT"
  end
end
