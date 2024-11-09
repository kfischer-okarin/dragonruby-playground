def test_calc_hit_count_ps_attacker(_args, assert)
  unit_group = { infantry: 1 }

  result = calc_hit_count_ps(unit_group, :attack)

  assert.equal! result, { 0 => Fraction[5, 6], 1 => Fraction[1, 6] }
end

def test_calc_hit_count_ps_defender(_args, assert)
  unit_group = { infantry: 1 }

  result = calc_hit_count_ps(unit_group, :defense)

  assert.equal! result, { 0 => Fraction[4, 6], 1 => Fraction[2, 6] }
end

def test_calc_hit_count_ps_multiple_units(_args, assert)
  unit_group = { infantry: 2 }

  result = calc_hit_count_ps(unit_group, :attack)

  expected = {
    0 => Fraction[5, 6] * Fraction[5, 6],
    1 => Fraction[5, 6] * Fraction[1, 6] * 2,
    2 => Fraction[1, 6] * Fraction[1, 6]
  }
  assert.equal! result, expected
end

def test_calc_win_p(_args, assert)
  attackers = { infantry: 1 }
  defenders = { infantry: 1 }

  result = calc_win_p(attackers, defenders)

  assert.equal! result, Fraction[1, 6] * Fraction[4, 6]
end
