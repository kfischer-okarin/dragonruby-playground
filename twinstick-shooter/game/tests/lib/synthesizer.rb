def test_vibrato(_args, assert)
  synthesizer = Synthesizer.new(4)
                           .sine_wave(100)
                           .vibrato(1, 0.1)

  frequencies = []
  4.times do
    synthesizer.next
    frequencies << synthesizer.generator.frequency.to_i
  end

  assert.equal! frequencies, [100, 110, 100, 90]
end

def test_tremolo(_args, assert)
  synthesizer = Synthesizer.new(4)
                           .sine_wave(100)
                           .tremolo(1, 0.1)

  amplitudes = []
  4.times do
    synthesizer.next
    amplitudes << synthesizer.generator.amplitude
  end

  assert.equal! amplitudes, [1, 1.1, 1, 0.9]
end

def test_modulate_pulse_width(_args, assert)
  synthesizer = Synthesizer.new(4)
                           .square_wave(100)
                           .modulate_pulse_width(1, 0.1)

  pulse_widths = []
  4.times do
    synthesizer.next
    pulse_widths << synthesizer.generator.pulse_width
  end

  assert.equal! pulse_widths, [0.5, 0.55, 0.5, 0.45]
end

def test_modulate(_args, assert)
  synthesizer = Synthesizer.new(4)
                           .square_wave(100)
                           .modulate(:frequency, type: :square, frequency: 1, amplitude: 0.1)

  frequencies = []
  4.times do
    synthesizer.next
    frequencies << synthesizer.generator.frequency.to_i
  end

  assert.equal! frequencies, [110, 110, 90, 90]
end

$gtk.reset 100
$gtk.log_level = :off
