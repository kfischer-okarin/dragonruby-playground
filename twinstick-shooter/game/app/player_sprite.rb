class PlayerSprite < Primitives::Sprite
  def initialize(player)
    super(Resources.sprites.character, w: 16, h: 16, source_w: 16, source_h: 16)
    @player = player
    self.orientation = [0, -1]
  end

  SOURCE_Y = {
    [0, 1] => 0,
    [1, 0] => 16,
    [0, -1] => 32,
    [-1, 0] => 16
  }.freeze

  def orientation=(value)
    @orientation = value
    @source_x = 16
    @source_y = SOURCE_Y[value]
    @flip_horizontally = value.x.negative?
  end

  def tick
    update_orientation
    update_position
  end

  def update_orientation
    return unless orientation_changed?

    self.orientation = movement_direction.y.zero? ? [movement_direction.x, 0] : [0, movement_direction.y]
  end

  def update_position
    @x = @player.position.x - 4
    @y = @player.position.y
  end

  def movement_direction
    @player.movement_direction
  end

  def orientation_changed?
    return false if movement_direction.zero?

    if @orientation.x.zero?
      movement_direction.y != @orientation.y
    else
      movement_direction.x != @orientation.x
    end
  end
end
