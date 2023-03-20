SAMPLE_RATE = 48_000
SAMPLE_TIMES = (0...SAMPLE_RATE).map { |i| i / SAMPLE_RATE.to_f }

def build_sound(sound_generator)
  sound = { t: 0 }
  sample_generator = lambda do
    result = SAMPLE_TIMES.map do |t|
      sound_generator.call(sound[:t] + t)
    end
    sound[:t] += 1.0
    result
  end
  sound[:input] = [1, SAMPLE_RATE, sample_generator]
  sound
end
