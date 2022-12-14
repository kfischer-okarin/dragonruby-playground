class Set
  include Enumerable

  def initialize(values = nil)
    @values = {}
    return unless values

    values.each do |v|
      self << v
    end
  end

  def <<(value)
    @values[value] = true
  end

  def delete(value)
    @values.delete(value)
  end

  def include?(value)
    @values.key? value
  end

  def empty?
    @values.empty?
  end

  def each(&block)
    @values.each_key(&block)
  end
end
