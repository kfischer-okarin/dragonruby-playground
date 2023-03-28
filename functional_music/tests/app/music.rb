def test_line(_args, assert)
  generator = line(1, 0.5, 1)

  assert.equal! generator.call(0), 1
  assert.equal! generator.call(0.5), 0.75
  assert.equal! generator.call(1), 0.5
  assert.equal! generator.call(1.5), 0.5
end

def test_clip_silence(_args, assert)
  generator = lambda do |t|
    case t
    when ..0.1 then 0.5
    when ..0.15 then 0.05
    when ..0.2 then 0.3
    when ..0.35 then 0.05
    when 0.35.. then 0.1
    end
  end

  clipped = clip_silence(generator, amp: 0.1, time: 0.1)

  inputs = (0..50).map { |i| i * 0.01 }
  outputs = inputs.map { |t| [t, clipped.call(t)] }.to_h

  values_string = outputs.map { |t, v| format("  %.2f: %.2f\n", t, v) }.join
  inputs.select { |t| t < 0.31 }.each do |t|
    assert.not_equal! outputs[t], 0, "Expected #{clipped.call(t)} to not be 0 at #{t}\n#{values_string}"
  end
  inputs.select { |t| t >= 0.31 }.each do |t|
    assert.equal! outputs[t], 0, "Expected #{clipped.call(t)} to be 0 at #{t}\n#{values_string}"
  end
end
