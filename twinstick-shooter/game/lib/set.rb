class Set
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

  def include?(value)
    @values.key? value
  end

  def empty?
    @values.empty?
  end

  def each(&block)
    @values.each_key do |k|
      block.call(k)
    end
  end
end
