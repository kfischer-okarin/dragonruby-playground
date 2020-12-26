def test_sawtooth_wave(_args, assert)
  generator = Generators::Sawtooth.new(sample_rate: 6, frequency: 2)
  samples = 6.map_with_index { generator.generate }

  assert.equal! samples, [1, 1 - (2 / 3), 1 - (4 / 3), 1, 1 - (2 / 3), 1 - (4 / 3)]
end

def test_sawtooth_wave_amplitude(_args, assert)
  generator = Generators::Sawtooth.new(sample_rate: 6, frequency: 2, amplitude: 2)
  samples = 6.map_with_index { generator.generate }

  assert.equal! samples, [2, 2 - (4 / 3), 2 - (8 / 3), 2, 2 - (4 / 3), 2 - (8 / 3)]
end

def test_square_wave(_args, assert)
  generator = Generators::Square.new(sample_rate: 4, frequency: 2)
  samples = 4.map_with_index { generator.generate }

  assert.equal! samples, [1, -1, 1, -1]
end

def test_square_wave_amplitude(_args, assert)
  generator = Generators::Square.new(sample_rate: 4, frequency: 2, amplitude: 3)
  samples = 4.map_with_index { generator.generate }

  assert.equal! samples, [3, -3, 3, -3]
end

def test_square_wave_phase_shift(_args, assert)
  generator = Generators::Square.new(sample_rate: 8, frequency: 2, phase_shift: Math::PI / 2)
  samples = 8.map_with_index { generator.generate }

  assert.equal! samples, [1, -1, -1, 1, 1, -1, -1, 1]
end

def test_square_wave_pulse_width(_args, assert)
  generator = Generators::Square.new(sample_rate: 8, frequency: 2, pulse_width: 0.25)
  samples = 8.map_with_index { generator.generate }

  assert.equal! samples, [1, -1, -1, -1, 1, -1, -1, -1]
end

$gtk.reset 100
$gtk.log_level = :off
