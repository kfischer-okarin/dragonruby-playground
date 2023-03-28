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

class AudioPlayer
  def initialize(sample_rate:)
    @sample_rate = sample_rate
    @sample_times = (0...sample_rate).map { |i| i / sample_rate.to_f }
    @next_channel = 1
    @queued_audios = []
  end

  def play(audio_source)
    audio = { t: 0 }
    sample_generator = lambda do
      result = []
      @sample_times.each do |t|
        result << audio_source.call(audio[:t] + t)
      end
      audio[:t] += 1.0
      result
    end
    audio[:input] = [1, @sample_rate, sample_generator]
    @queued_audios << audio
  end

  def tick(args)
    @queued_audios.each do |audio|
      args.audio[free_channel] = audio
    end
    @queued_audios.clear
  end

  private

  def free_channel
    channel = :"channel#{@next_channel}"
    @next_channel += 1
    channel
  end
end
