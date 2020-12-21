class PlayerSprite < Primitives::Sprite
  def initialize(player)
    super(Resources.sprites.character, w: 16, h: 16, source_w: 16, source_h: 16)
    @player = player
    self.orientation = [0, -1]
    @frame = 0
  end

  WALK_SOURCE_Y = {
    [0, 1] => 48,
    [1, 0] => 64,
    [0, -1] => 80,
    [-1, 0] => 64
  }.freeze

  SHOOT_SOURCE_Y = {
    [0, 1] => 0,
    [1, 0] => 16,
    [0, -1] => 32,
    [-1, 0] => 16
  }.freeze

  FRAMES = [0] * 5 + [16] * 5 + [32] * 5 + [16] * 5

  def orientation=(value)
    @orientation = value
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

    self.orientation = direction.y.zero? ? [direction.x, 0] : [0, direction.y]
  end

  def update_position
    @x = @player.position.x - 8
    @y = @player.position.y - 1
  end

  def update_animation_frame
    @source_y = shooting? ? SHOOT_SOURCE_Y[@orientation] : WALK_SOURCE_Y[@orientation]
    if @player.movement_direction.zero?
      @source_x = 16
      @frame = 0
    else
      @source_x = FRAMES[@frame]
      @frame = (@frame + 1) % FRAMES.size
    end
  end

  def shooting?
    !@player.fire_direction.zero?
  end

  def direction
    if shooting?
      @player.fire_direction
    else
      @player.movement_direction
    end
  end

  def orientation_changed?
    return false if direction.zero?

    if @orientation.x.zero?
      direction.y != @orientation.y
    else
      direction.x != @orientation.x
    end
  end
end
