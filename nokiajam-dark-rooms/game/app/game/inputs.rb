class Game
  # Specialized Outputs for Nokia Jam
  class Inputs
    attr_reader :toggle_light

    def collect(gtk_inputs)
      @toggle_light ||= gtk_inputs.keyboard.key_down.space
    end
  end
end
