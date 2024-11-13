class BigInteger
  include Comparable

  def initialize(value = nil, reversed_digits: nil, negative: nil)
    if reversed_digits && !negative.nil?
      @reversed_digits = reversed_digits
      @negative = negative
    else
      case value
      when Integer, String
        value = value.to_s
        @reversed_digits = value.chars.map(&:to_i).reverse
        @negative = false
        if value.chars.first == '-'
          @reversed_digits.pop
          @negative = true
        end
      else
        raise TypeError, "Cannot create BigInteger from #{value.class}"
      end
    end

    remove_leading_zeros(@reversed_digits)
    @reversed_digits.freeze
  end

  def self.[](value)
    new(value)
  end

  def positive?
    !@negative
  end

  def negative?
    @negative
  end

  def zero?
    @reversed_digits == [0] && !@negative
  end

  def -@
    BigInteger.new(reversed_digits: @reversed_digits, negative: !@negative)
  end

  def abs
    @negative ? -self : self
  end

  def +(other)
    return self + BigInteger[other] if other.is_a?(Integer)
    return self - -other if other.negative?
    return other - -self if @negative && !other.negative?

    result_reversed_digits = []
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

      result_reversed_digits << sum
    end
    result_reversed_digits << carry if carry.positive?

    BigInteger.new(reversed_digits: result_reversed_digits, negative: @negative)
  end

  def -(other)
    return self - BigInteger[other] if other.is_a?(Integer)
    return -(other - self) if self < other
    return self + -other if other.negative?

    result_reversed_digits = []
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

      result_reversed_digits << difference
    end

    BigInteger.new(reversed_digits: result_reversed_digits, negative: @negative)
  end

  def *(other)
    return self * BigInteger[other] if other.is_a?(Integer)

    result_reversed_digits = []

    other_reversed_digits = other.instance_variable_get(:@reversed_digits).dup

    # Handle final zeros of other first
    while other_reversed_digits.first.zero? && other_reversed_digits.length > 1
      other_reversed_digits.shift
      result_reversed_digits << 0
    end

    case other_reversed_digits.length
    when 1
      carry = 0
      @reversed_digits.each do |digit|
        product = digit * other_reversed_digits[0] + carry
        carry, result_digit = product.divmod(10)
        result_reversed_digits << result_digit
      end
      result_reversed_digits << carry if carry.positive?
      BigInteger.new(reversed_digits: result_reversed_digits, negative: @negative ^ other.negative?)
    else
      result = BigInteger[0]
      base_digits = result_reversed_digits.dup
      until other_reversed_digits.empty?
        sub_result = self * BigInteger.new(
          reversed_digits: [*base_digits, other_reversed_digits.shift],
          negative: other.negative?
        )
        result += sub_result
        base_digits << 0
      end
      result
    end
  end

  def /(other)
    to_s.to_f / other.to_s.to_f
  end

  def idiv(other)
    divmod(other).first
  end

  def %(other)
    divmod(other).last
  end

  def divmod(other)
    return divmod(BigInteger[other]) if other.is_a?(Integer)

    multiples_of_other = (0..9).map { |i| other.abs * i }
    current_dividend = BigInteger[0]
    digit_count = @reversed_digits.length
    digit_index = digit_count - 1
    result_digits = []
    while digit_index >= 0
      current_dividend = current_dividend * 10 + BigInteger[@reversed_digits[digit_index]]
      division_result = multiples_of_other.find_index { |multiple| multiple > current_dividend } - 1
      result_digits << division_result
      current_dividend -= multiples_of_other[division_result]
      digit_index -= 1
    end
    result_digits.reverse!

    quotient = BigInteger.new(reversed_digits: result_digits, negative: false)
    one_is_negative = @negative ^ other.negative?
    quotient = -quotient - 1 if one_is_negative
    modulus = self - quotient * other
    [quotient, modulus]
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

  private

  def remove_leading_zeros(reversed_digits)
    reversed_digits.pop while reversed_digits.last.zero? && reversed_digits.length > 1
  end
end
