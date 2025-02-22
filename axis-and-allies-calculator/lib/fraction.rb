class Fraction
  include Comparable

  attr_reader :numerator, :denominator

  def initialize(numerator, denominator = 1)
    raise TypeError, 'Fraction only accepts integers' unless integer?(numerator) && integer?(denominator)
    raise ZeroDivisionError, 'Denominator cannot be zero' if denominator.zero?

    gcd = self.class.greatest_common_divisor(numerator, denominator)
    @numerator = numerator.idiv(gcd)
    @denominator = denominator.idiv(gcd)
  end

  class << self
    def [](numerator, denominator = 1)
      new(numerator, denominator)
    end

    def greatest_common_divisor(a, b)
      until b.zero?
        remainder = a % b
        a = b
        b = remainder
      end

      a
    end
  end

  def -@
    Fraction.new(-@numerator, @denominator)
  end

  def +(other)
    case other
    when Fraction, *integer_classes
      other = Fraction[other] unless other.is_a?(Fraction)

      Fraction.new(
        @numerator * other.denominator + other.numerator * @denominator,
        @denominator * other.denominator
      )
    when Float
      to_f + other
    end
  end

  def -(other)
    self + -other
  end

  def *(other)
    case other
    when Fraction, *integer_classes
      other = Fraction[other] unless other.is_a?(Fraction)

      Fraction.new(@numerator * other.numerator, @denominator * other.denominator)
    when Float
      to_f * other
    end
  end

  def /(other)
    case other
    when Fraction, *integer_classes
      other = Fraction[other] unless other.is_a?(Fraction)

      self * Fraction.new(other.denominator, other.numerator)
    when Float
      to_f / other
    end
  end

  def <=>(other)
    case other
    when Fraction, *integer_classes
      other = Fraction[other] unless other.is_a?(Fraction)

      @numerator * other.denominator <=> other.numerator * @denominator
    when Float
      to_f <=> other
    end
  end

  def ==(other)
    case other
    when Fraction, *integer_classes
      other = Fraction[other] unless other.is_a?(Fraction)

      @numerator == other.numerator && @denominator == other.denominator
    when Float
      to_f == other
    end
  end

  def floor
    to_f.floor
  end

  def ceil
    to_f.ceil
  end

  def to_f
    @numerator / @denominator
  end

  def to_s
    "#{@numerator}/#{@denominator}"
  end

  alias inspect to_s

  private

  def integer?(value)
    integer_classes.any? { |klass| value.is_a?(klass) }
  end

  def integer_classes
    [Integer]
  end
end
