class BigInteger
  include Comparable

  def initialize(value = nil, reversed_digits: nil, negative: nil)
    if reversed_digits && !negative.nil?
      @reversed_digits = reversed_digits
      @negative = negative
      return
    end

    value = value.to_s
    @reversed_digits = value.chars.map(&:to_i).reverse
    @negative = false
    if value.chars.first == '-'
      @reversed_digits.pop
      @negative = true
    end
  end

  def self.[](value)
    new(value)
  end

  def negative?
    @negative
  end

  def -@
    BigInteger.new(reversed_digits: @reversed_digits, negative: !@negative)
  end

  def +(other)
    return self - -other if other.negative?
    return other - -self if @negative && !other.negative?

    result = []
    other_reversed_digits = other.instance_variable_get(:@reversed_digits)
    digit_count = [@reversed_digits.length, other_reversed_digits.length].max

    carry = 0
    digit_count.times do |index|
      digit = @reversed_digits[index] || 0
      other_digit = other_reversed_digits[index] || 0
      sum = digit + other_digit + carry

      carry = 0
      if sum >= 10
        sum -= 10
        carry = 1
      end

      result << sum
    end
    result << carry if carry.positive?

    BigInteger.new(reversed_digits: result, negative: @negative)
  end

  def -(other)
    return -(other - self) if self < other
    return self + -other if other.negative?

    result = []
    other_reversed_digits = other.instance_variable_get(:@reversed_digits)
    digit_count = [@reversed_digits.length, other_reversed_digits.length].max

    borrow = 0
    digit_count.times do |index|
      digit = @reversed_digits[index] || 0
      other_digit = other_reversed_digits[index] || 0
      difference = digit - other_digit - borrow

      borrow = 0
      if difference.negative?
        difference += 10
        borrow = 1
      end

      result << difference
    end

    result.pop while result.last.zero? && result.length > 1

    BigInteger.new(reversed_digits: result, negative: @negative)
  end

  def ==(other)
    case other
    when Integer
      BigInteger[other] == self
    when BigInteger
      @reversed_digits == other.instance_variable_get(:@reversed_digits) &&
        @negative == other.negative?
    end
  end

  def <=>(other)
    return self <=> BigInteger[other] if other.is_a?(Integer)

    return -1 if @negative && !other.negative?
    return 1 if !@negative && other.negative?

    other_reversed_digits = other.instance_variable_get(:@reversed_digits)
    result = if @reversed_digits.length > other_reversed_digits.length
               1
             elsif @reversed_digits.length < other_reversed_digits.length
               -1
             else
               @reversed_digits.reverse <=> other_reversed_digits.reverse
             end

    @negative ? -result : result
  end

  def to_s
    sign = @negative ? '-' : ''
    "#{sign}#{@reversed_digits.reverse.join}"
  end

  def inspect
    "BigInteger['#{self}']"
  end
end
