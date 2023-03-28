def test_audio_player_play_creates_audio(args, assert)
  player = AudioPlayer.new sample_rate: 5
  generator = ->(t) { t < 1 ? t : 2 - t }

  player.play generator
  player.tick(args)

  assert.equal! args.audio.keys, %i[channel1], 'Expected playing audio with key :channel1'
  audio = args.audio[:channel1]
  input = audio[:input]
  assert.equal! input[0], 1, 'Expected input to be mono'
  assert.equal! input[1], 5, 'Expected input to be 5 samples per second'
  assert.equal! audio[:t], 0, 'Expected audio to start at time 0'
  assert.equal! rounded_values(input[2].call), [0, 0.2, 0.4, 0.6, 0.8]
  assert.equal! audio[:t], 1, 'Expected audio to have advanced to time 1'
  assert.equal! rounded_values(input[2].call), [1, 0.8, 0.6, 0.4, 0.2]
  assert.equal! audio[:t], 2, 'Expected audio to have advanced to time 2'
end

def test_audio_player_play_can_play_on_several_channels(args, assert)
  player = AudioPlayer.new sample_rate: 5
  generator = ->(t) { t < 1 ? t : 2 - t }

  player.play generator
  player.play generator
  player.tick(args)

  assert.equal! args.audio.keys, %i[channel1 channel2], 'Expected playing audios with keys :channel1, :channel2'
end

def test_audio_player_removes_audio_that_returns_finish_audio(args, assert)
  player = AudioPlayer.new sample_rate: 5
  generator = ->(t) { t < 0.8 ? t : :finish_audio }

  player.play generator
  player.tick(args)

  assert.equal! args.audio.keys, %i[channel1], 'Expected playing audio with key :channel1'

  audio = args.audio[:channel1]
  input = audio[:input]
  assert.equal! rounded_values(input[2].call), [0, 0.2, 0.4, 0.6], 'Expected audio to return only samples until t=0.8'

  player.tick(args)

  assert.equal! args.audio.keys, %i[channel1], 'Expected audio to be still playing'
  assert.equal! rounded_values(input[2].call), [], 'Expected audio to return no samples after t=0.8'

  player.tick(args)

  assert.equal! args.audio.keys, [], 'Expected audio to have been removed'
end

def test_audio_player_reuses_channels(args, assert)
  player = AudioPlayer.new sample_rate: 5
  generator = ->(t) { :finish_audio }

  player.play generator
  player.tick(args)

  assert.equal! args.audio.keys, %i[channel1], 'Expected playing audio with key :channel1'

  play_until_finished(args, player, :channel1)

  player.play generator
  player.tick(args)

  assert.equal! args.audio.keys, %i[channel1], 'Expected playing audio with key :channel1'
end

def rounded_values(array)
  array.map { |v| v.round(2) }
end

def play_until_finished(args, player, channel)
  iterations = 0
  while args.audio.key? channel
    args.audio[channel][:input][2].call
    player.tick(args)
    iterations += 1
    raise 'Channel did not stop after 1000 iterations' if iterations > 1000
  end
end
