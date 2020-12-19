DirectionalInput = Struct.new(:up_button, :left_button, :down_button, :right_button) do
  def value(gtk_inputs)
    key_held = gtk_inputs.keyboard.key_held
    [0, 0].tap { |result|
      result.x += 1 if key_held.send(right_button)
      result.x -= 1 if key_held.send(left_button)
      result.y += 1 if key_held.send(up_button)
      result.y -= 1 if key_held.send(down_button)
    }
  end
end
