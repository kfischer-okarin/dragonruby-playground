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

def rounded_values(array)
  array.map { |v| v.round(2) }
end
