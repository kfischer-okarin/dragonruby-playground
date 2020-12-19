class Entity
  def initialize(values)
    @component_types = Set.new

    values.each do |key, value|
      @component_types << key

      define_singleton_method key do
        value
      end
    end
  end

  def component_types
    @component_types.enum_for(:each)
  end
end
