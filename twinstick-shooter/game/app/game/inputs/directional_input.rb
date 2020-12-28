class KeyboardDirectionalInput
  def initialize(up_button, left_button, down_button, right_button)
    @x_axis = KeyboardInputAxis.new(right_button, left_button)
    @y_axis = KeyboardInputAxis.new(up_button, down_button)
  end

  def value(gtk_inputs)
    [@x_axis.value(gtk_inputs), @y_axis.value(gtk_inputs)]
  end
end

KeyboardInputAxis = Struct.new(:positive_button, :negative_button) do
  def value(gtk_inputs)
    key_held = gtk_inputs.keyboard.key_held
    result = 0
    result += 1 if key_held.send(positive_button)
    result -= 1 if key_held.send(negative_button)
    result
  end
end
