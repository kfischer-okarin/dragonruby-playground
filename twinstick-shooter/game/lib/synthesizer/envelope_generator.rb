class EnvelopeGenerator
  Slope = Struct.new(:duration, :level)

  def self.adsr(sample_rate, attack, decay, sustain, release)
    new(sample_rate, [Slope.new(attack, 1), Slope.new(decay, sustain)], [Slope.new(release, 0)])
  end

  def initialize(sample_rate, attack_phases, release_phases)
    @sample_rate = sample_rate
    @phases = {
      attack: attack_phases,
      release: release_phases
    }
    @last_value = 0
    switch_to_phase(:attack, 0)
  end

  def attack
    switch_to_phase(:attack, 0)
  end

  def release
    switch_to_phase(:release, 0)
  end

  def release_duration
    @phases[:release].reduce(0) { |memo, phase| memo + phase.duration }
  end

  def next
    return @last_value if @mode == :sustain

    value = @last_value + @increment
    @sample_index += 1
    if phase_finished?
      value = @phase.level
      go_to_next_phase
    end

    @last_value = value
  end

  private

  def phase_finished?
    @sample_index >= @phase_sample_count
  end

  def switch_to_phase(mode, index)
    @mode = mode
    @phase_index = index
    @phase = @phases[@mode][@phase_index]
    @sample_index = 0
    @phase_sample_count = (@phase.duration * @sample_rate).ceil
    @increment = (@phase.level - @last_value) / @phase_sample_count
  end

  def go_to_next_phase
    next_phase_index = @phase_index + 1
    mode_finished = @phases[@mode][next_phase_index].nil?
    if mode_finished
      @mode = :sustain
    else
      switch_to_phase(@mode, next_phase_index)
    end
  end
end
