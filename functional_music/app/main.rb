require 'app/music.rb'
require 'app/dr_interface.rb'

def tick(args)
  # args.audio[:sound] ||= build_sound tone(300)
  # args.audio[:sound] ||= build_sound doubletone(300, 300.5)
  # args.audio[:sound] ||= build_sound beep(300)
  # args.audio[:sound] ||= build_sound bell(300)
  # args.audio[:sound] ||= build_sound bell(600)
  # args.audio[:sound] ||= build_sound bell(500, 10, 0)
  args.audio[:sound] ||= build_sound bell(400, 10, 0, 0)
end

def tone(frequency = 440)
  sin_osc(frequency)
end

def doubletone(freq1 = 440, freq2 = 440)
  sin_osc(freq1) + sin_osc(freq2)
end

def beep(frequency = 440, duration = 1)
  envelope = line(1, 0, duration)
  tone(frequency) * envelope
end

def bell(frequency = 440, duration = 10, h0 = 1, h1 = 0.6, h2 = 0.4, h3 = 0.25, h4 = 0.2, h5 = 0.15)
  harmonic_series = [1, 2, 3, 4.2, 5.4, 6.8]
  proportions = [h0, h1, h2, h3, h4, h5]
  components = harmonic_series.zip(proportions).map do |harmonic, proportion|
    tone(frequency * harmonic) * perc(release: proportion * duration, level: proportion * 0.5)
  end
  clip_silence(mix(components))
end

$gtk.reset
