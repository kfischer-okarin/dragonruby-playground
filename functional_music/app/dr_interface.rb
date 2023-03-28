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
    @available_channels = []
    @queued_audios = []
  end

  def play(audio_source)
    audio = { t: 0 }
    sample_generator = lambda do
      result = []
      if audio[:finish_after_next_samples]
        audio[:finished] = true
        return result
      end

      @sample_times.each do |t|
        value = audio_source.call(audio[:t] + t)
        if value == :finish_audio
          audio[:finish_after_next_samples] = true
          break
        end

        result << value
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

    finished_audios = args.audio.keys.select { |id|
      args.audio[id][:finished]
    }
    finished_audios.each do |id|
      args.audio.delete(id)
      @available_channels << id
    end
  end

  private

  def free_channel
    return @available_channels.pop if @available_channels.any?

    channel = :"channel#{@next_channel}"
    @next_channel += 1
    channel
  end
end
