# Sorted list that makes assumptions:
# - No elements are added or removed
# - If element sort key changes then only slightly
class BubbleSortedList
  include Enumerable

  def initialize(values, &sort_key)
    @sort_key = sort_key
    @indexes = {}
    @values = []
    values.sort_by(&@sort_key).each_with_index do |value, index|
      @values << value
      @indexes[value] = index
    end
  end

  def value(index)
    @values.value(index)
  end

  def length
    @values.length
  end

  def each(&block)
    @values.each do |value|
      block.call(value)
    end
  end

  def fix_sort_order(value)
    current_index = @indexes[value]
    while should_be_swapped?(current_index - 1, current_index)
      swap(current_index - 1, current_index)
      current_index -= 1
    end
    while should_be_swapped?(current_index, current_index + 1)
      swap(current_index, current_index + 1)
      current_index += 1
    end
  end

  private

  def should_be_swapped?(left_index, right_index)
    return false if left_index.negative? || right_index >= length

    @sort_key.call(@values[right_index]) < @sort_key.call(@values[left_index])
  end

  def swap(index1, index2)
    value1 = @values[index1]
    value2 = @values[index2]
    @values[index1] = value2
    @values[index2] = value1
    @indexes[value1] = index2
    @indexes[value2] = index1
  end
end
