require 'app/music.rb'
require 'app/dr_interface.rb'

def tick(args)
  # args.audio[:sound] ||= build_sound tone(300)
  # args.audio[:sound] ||= build_sound doubletone(300, 300.5)
  args.audio[:sound] ||= build_sound beep(300)
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

$gtk.reset
