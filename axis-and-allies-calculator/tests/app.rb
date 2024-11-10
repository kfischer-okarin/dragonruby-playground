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

def test_attacker_casualties_same_units(_args, assert)
  attackers = { infantry: 2 }

  result = remove_attacker_casualties(attackers, 1)

  assert.equal! result, { infantry: 1 }
end

def test_attacker_casualties_remove_weakest_unit(_args, assert)
  attackers = { armor: 1, infantry: 1 }

  result = remove_attacker_casualties(attackers, 1)

  assert.equal! result, { armor: 1 }
end

def test_attacker_casualties_remove_cheapest_unit_if_tie(_args, assert)
  attackers = { fighter: 1, armor: 1 } # both attack: 3 but armor is cheaper

  result = remove_attacker_casualties(attackers, 1)

  assert.equal! result, { fighter: 1 }
end

def test_attacker_casualties_cannot_remove_more_units_than_present(_args, assert)
  attackers = { fighter: 1, armor: 1 }

  result = remove_attacker_casualties(attackers, 3)

  assert.equal! result, {}
end

def test_defender_casualties_same_units(_args, assert)
  defenders = { infantry: 2 }

  result = remove_defender_casualties(defenders, 1)

  assert.equal! result, { infantry: 1 }
end

def test_defender_casualties_remove_weakest_unit(_args, assert)
  defenders = { bomber: 1, infantry: 1 }

  result = remove_defender_casualties(defenders, 1)

  assert.equal! result, { infantry: 1 }
end

def test_defender_casualties_remove_cheapest_unit_if_tie(_args, assert)
  defenders = { armor: 1, infantry: 1 } # both defense: 2 but infantry is cheaper

  result = remove_defender_casualties(defenders, 1)

  assert.equal! result, { armor: 1 }
end

def test_defender_casualties_cannot_remove_more_units_than_present(_args, assert)
  defenders = { armor: 1, infantry: 1 }

  result = remove_defender_casualties(defenders, 3)

  assert.equal! result, {}
end

def test_calc_next_round_ps(_args, assert)
  start_ps = { [{ infantry: 2 }, { infantry: 1 }] => Fraction[1] }

  result = calc_next_round_ps(start_ps)

  # hits: { 0 => 25/36, 1 => 10/36, 2 => 1/36 } vs { 0 => 4/6, 1 => 2/6 }
  # next states
  # - 2 vs 0 -> (10/36 + 1/36) * 4/6
  # - 1 vs 0 -> (10/36 + 1/36) * 2/6
  # - 2 vs 1 -> 25/36 * 4/6
  # - 1 vs 1 -> 25/36 * 2/6
  expected = {
    [{ infantry: 2 }, {}] => Fraction[11, 36] * Fraction[4, 6],
    [{ infantry: 1 }, {}] => Fraction[11, 36] * Fraction[2, 6],
    [{ infantry: 2 }, { infantry: 1 }] => Fraction[25, 36] * Fraction[4, 6],
    [{ infantry: 1 }, { infantry: 1 }] => Fraction[25, 36] * Fraction[2, 6]
  }
  assert.equal! result, expected
end

def test_calc_next_round_ps_second_round(_args, assert)
  start_ps = {
    [{ infantry: 2 }, {}] => Fraction[11, 36] * Fraction[4, 6],
    [{ infantry: 1 }, {}] => Fraction[11, 36] * Fraction[2, 6],
    [{ infantry: 2 }, { infantry: 1 }] => Fraction[25, 36] * Fraction[4, 6],
    [{ infantry: 1 }, { infantry: 1 }] => Fraction[25, 36] * Fraction[2, 6]
  }

  result = calc_next_round_ps(start_ps)

  expected = {
    [{ infantry: 2 }, {}] => (
      # 2 vs 1 -> 2 vs 0
      Fraction[11, 36] * Fraction[4, 6] +
      # 2 vs 1 -> 2 vs 1 -> 2 vs 0
      (Fraction[25, 36] * Fraction[4, 6]) * (Fraction[11, 36] * Fraction[4, 6])
    ),
    [{ infantry: 1 }, {}] => (
      # 2 vs 1 -> 1 vs 0
      Fraction[11, 36] * Fraction[2, 6] +
      # 2 vs 1 -> 2 vs 1 -> 1 vs 0
      (Fraction[25, 36] * Fraction[4, 6]) * (Fraction[11, 36] * Fraction[2, 6]) +
      # 2 vs 1 -> 1 vs 1 -> 1 vs 0
      (Fraction[25, 36] * Fraction[2, 6]) * (Fraction[1, 6] * Fraction[4, 6])
    ),
    [{ infantry: 2 }, { infantry: 1 }] => (
      # 2 vs 1 -> 2 vs 1 -> 2 vs 1
      (Fraction[25, 36] * Fraction[4, 6]) * (Fraction[25, 36] * Fraction[4, 6])
    ),
    [{ infantry: 1 }, { infantry: 1 }] => (
      # 2 vs 1 -> 2 vs 1 -> 1 vs 1
      (Fraction[25, 36] * Fraction[4, 6]) * (Fraction[25, 36] * Fraction[2, 6]) +
      # 2 vs 1 -> 1 vs 1 -> 1 vs 1
      (Fraction[25, 36] * Fraction[2, 6]) * (Fraction[5, 6] * Fraction[4, 6])
    ),
    [{}, { infantry: 1 }] => (
      # 2 vs 1 -> 1 vs 1 -> 0 vs 1
      (Fraction[25, 36] * Fraction[2, 6]) * (Fraction[5, 6] * Fraction[2, 6])
    ),
    [{}, {}] => (
      # 2 vs 1 -> 1 vs 1 -> 0 vs 0
      (Fraction[25, 36] * Fraction[2, 6]) * (Fraction[1, 6] * Fraction[2, 6])
    )
  }

  assert.equal! result, expected
end
