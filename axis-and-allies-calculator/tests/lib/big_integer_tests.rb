def test_big_integer_from_string(_args, assert)
  assert.equal! BigInteger['123'].to_s, '123'
  assert.equal! BigInteger['-123'].to_s, '-123'
end

def test_big_integer_from_integer(_args, assert)
  assert.equal! BigInteger[123].to_s, '123'
  assert.equal! BigInteger[-123].to_s, '-123'
end

def test_big_integer_equality_considers_sign(_args, assert)
  assert.not_equal! BigInteger['123'], BigInteger['-123']
end

def test_big_integer_equality_to_integer(_args, assert)
  assert.equal! BigInteger['123'], 123
  assert.equal! BigInteger['-123'], -123
end

def test_big_integer_comparison(_args, assert)
  assert.true! BigInteger['123'] > BigInteger['122']
  assert.true! BigInteger['123'] >= BigInteger['123']
  assert.true! BigInteger['123'] >= BigInteger['122']
  assert.true! BigInteger['122'] < BigInteger['123']
  assert.true! BigInteger['123'] <= BigInteger['123']
  assert.true! BigInteger['122'] <= BigInteger['123']

  assert.true! BigInteger['-123'] < BigInteger['-122']
end

def test_big_integer_comparison_with_integer(_args, assert)
  assert.true! BigInteger['123'] > 122
  assert.true! BigInteger['-123'] < -122
end

def test_big_integer_addition(_args, assert)
  assert.equal! BigInteger['123'] + BigInteger['456'], BigInteger['579']
  assert.equal! BigInteger['123'] + BigInteger['0'], BigInteger['123']
  assert.equal! BigInteger['9'] + BigInteger['6'], BigInteger['15']
  assert.equal! BigInteger['1'] + BigInteger['22'], BigInteger['23']
  assert.equal! BigInteger['5'] + BigInteger['-3'], BigInteger['2']
  assert.equal! BigInteger['-5'] + BigInteger['3'], BigInteger['-2']
  assert.equal! BigInteger['-5'] + BigInteger['-3'], BigInteger['-8']
end

def test_big_integer_subtraction(_args, assert)
  assert.equal! BigInteger['123'] - BigInteger['11'], BigInteger['112']
  assert.equal! BigInteger['123'] - BigInteger['0'], BigInteger['123']
  assert.equal! BigInteger['16'] - BigInteger['9'], BigInteger['7']
  assert.equal! BigInteger['9'] - BigInteger['16'], BigInteger['-7']
  assert.equal! BigInteger['9'] - BigInteger['-16'], BigInteger['25']
  assert.equal! BigInteger['-9'] - BigInteger['16'], BigInteger['-25']
  assert.equal! BigInteger['-9'] - BigInteger['-16'], BigInteger['7']
end

def test_big_integer_multiplication(_args, assert)
  assert.equal! BigInteger['3'] * BigInteger['4'], BigInteger['12']
  assert.equal! BigInteger['3'] * BigInteger['0'], BigInteger['0']
  assert.equal! BigInteger['23'] * BigInteger['4'], BigInteger['92']
  assert.equal! BigInteger['23'] * BigInteger['10'], BigInteger['230']
  assert.equal! BigInteger['77'] * BigInteger['100'], BigInteger['7700']
  assert.equal! BigInteger['12'] * BigInteger['12'], BigInteger['144']
  assert.equal! BigInteger['-12'] * BigInteger['12'], BigInteger['-144']
  assert.equal! BigInteger['-12'] * BigInteger['-12'], BigInteger['144']
  assert.equal! BigInteger['2000'] * BigInteger['0'], BigInteger['0']
end

def test_big_integer_negation(_args, assert)
  assert.equal! (-BigInteger['123']), BigInteger['-123']
  assert.equal! (-BigInteger['-123']), BigInteger['123']
end

def test_big_integer_negative(_args, assert)
  assert.true! BigInteger['-123'].negative?
  assert.false! BigInteger['123'].negative?
end

def test_big_integer_positive(_args, assert)
  assert.true! BigInteger['123'].positive?
  assert.false! BigInteger['-123'].positive?
end

def test_big_integer_zero(_args, assert)
  assert.true! BigInteger['0'].zero?
  assert.false! BigInteger['1'].zero?
  assert.false! BigInteger['-1'].zero?
end
