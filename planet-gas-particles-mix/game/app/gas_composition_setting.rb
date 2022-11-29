class GasCompositionSetting < UI::Panel
  MOLECULE_COLORS = [
    { r: 228, g: 59, b: 68 },
    { r: 62, g: 137, b: 72 },
    { r: 0, g: 149, b: 233 }
  ].freeze

  def initialize(particles)
    super(x: 30, y: 30, w: 1220, h: 100)
    @particles = particles
    @layout = UI::Layout.new(self, padding_vertical: 32, padding_horizontal: 20)
    @ratios = UI::RatioSlider.new(colors: MOLECULE_COLORS)
    @ratios.input_handlers << method(:on_ratio_changed)
    on_ratio_changed(@ratios.thumb_values)
    build_layout
  end

  private

  def build_layout
    @layout << @ratios
    self << @layout
  end

  def on_ratio_changed(thumb_values)
    threshold_indexes = [0, *thumb_values, 1].map { |value| value * @particles.size }
    (0...(threshold_indexes.size - 1)).each do |index|
      left = threshold_indexes[index]
      right = threshold_indexes[index + 1]
      @particles[left..right].each do |particle|
        color = MOLECULE_COLORS[index]
        particle.r = color.r
        particle.g = color.g
        particle.b = color.b
      end
    end
  end
end
