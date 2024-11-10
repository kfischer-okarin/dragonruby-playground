def test_fraction_assumes_denominator_of_1_when_not_provided(_args, assert)
  assert.equal! Fraction[1], Fraction[1, 1]
end

def test_fraction_reduces_to_lowest_terms(_args, assert)
  assert.equal! Fraction[2, 4], Fraction[1, 2]
end

def test_fraction_ensures_positive_denominator(_args, assert)
  value = Fraction[1, -2]
  assert.equal! value.numerator, -1
  assert.equal! value.denominator, 2
end

def test_fraction_only_allows_integer_values(_args, assert)
  Fraction[1.5, 2]
  assert.fail 'Expected to raise an error'
rescue TypeError
  assert.ok!
end

def test_fraction_division_by_zero(_args, assert)
  Fraction[1, 0]
  assert.fail 'Expected to raise an error'
rescue ZeroDivisionError
  assert.ok!
end

def test_fraction_addition(_args, assert)
  assert.equal! Fraction[1, 2] + Fraction[1, 3], Fraction[5, 6]
  assert.equal! Fraction[1, 2] + 5, Fraction[11, 2]
  assert.equal! Fraction[1, 2] + 0.5, 1
end

def test_fration_negation(_args, assert)
  assert.equal!(-Fraction[1, 2], Fraction[-1, 2])
end

def test_fraction_subtraction(_args, assert)
  assert.equal! Fraction[1, 2] - Fraction[1, 3], Fraction[1, 6]
  assert.equal! Fraction[1, 2] - 5, Fraction[-9, 2]
  assert.equal! Fraction[1, 2] - 0.5, 0
end

def test_fraction_multiplication(_args, assert)
  assert.equal! Fraction[1, 2] * Fraction[1, 3], Fraction[1, 6]
  assert.equal! Fraction[1, 2] * 5, Fraction[5, 2]
  assert.equal! Fraction[1, 2] * 0.5, 0.25
end

def test_fraction_division(_args, assert)
  assert.equal! Fraction[1, 2] / Fraction[1, 3], Fraction[3, 2]
  assert.equal! Fraction[1, 2] / 5, Fraction[1, 10]
  assert.equal! Fraction[1, 2] / 0.5, 1
end

def test_fraction_comparison(_args, assert)
  assert.true! Fraction[1, 2] < Fraction[2, 3]
  assert.true! Fraction[1, 2] < 1
  assert.true! Fraction[1, 2] <= 1
  assert.true! Fraction[1, 2] == Fraction[1, 2]
  assert.true! Fraction[1, 2] == 0.5
  assert.true! Fraction[1, 2] >= 0.5
  assert.true! Fraction[1, 2] > 0.4
end

def test_fraction_to_f(_args, assert)
  assert.equal! Fraction[1, 2].to_f, 0.5
end

def test_fraction_floor(_args, assert)
  assert.equal! Fraction[1, 2].floor, 0
  assert.equal! Fraction[3, 2].floor, 1
end

def test_fraction_ceil(_args, assert)
  assert.equal! Fraction[1, 2].ceil, 1
  assert.equal! Fraction[3, 2].ceil, 2
end
