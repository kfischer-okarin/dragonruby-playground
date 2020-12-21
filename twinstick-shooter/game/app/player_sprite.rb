class PlayerSprite < Primitives::Sprite
  def initialize(player)
    super(Resources.sprites.character, w: 16, h: 16, source_w: 16, source_h: 16)
    @player = player
    self.orientation = [0, -1]
    @frame = 0
  end

  SOURCE_Y = {
    [0, 1] => 0,
    [1, 0] => 16,
    [0, -1] => 32,
    [-1, 0] => 16
  }.freeze

  FRAMES = [0] * 5 + [16] * 5 + [32] * 5 + [16] * 5

  def orientation=(value)
    @orientation = value
    @source_y = SOURCE_Y[value]
    @flip_horizontally = value.x.negative?
    @frame = 0
  end

  def tick
    update_orientation
    update_position
    update_animation_frame
  end

  def update_orientation
    return unless orientation_changed?

    self.orientation = movement_direction.y.zero? ? [movement_direction.x, 0] : [0, movement_direction.y]
  end

  def update_position
    @x = @player.position.x - 3
    @y = @player.position.y - 1
  end

  def update_animation_frame
    if movement_direction.zero?
      @source_x = 16
      @frame = 0
    else
      @source_x = FRAMES[@frame]
      @frame = (@frame + 1) % FRAMES.size
    end
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
