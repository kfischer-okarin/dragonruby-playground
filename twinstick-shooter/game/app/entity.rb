class Entity
  def initialize(values)
    @component_types = Set.new

    values.each do |key, value|
      @component_types << key

      if value.is_a? Proc
        define_singleton_method key do
          value.call(self)
        end
      else
        define_singleton_method key do
          instance_variable_get(:"@#{key}")
        end

        define_singleton_method "#{key}=" do |new_value|
          instance_variable_set(:"@#{key}", new_value)
        end

        instance_variable_set(:"@#{key}", value)
      end
    end
  end

  def component_types
    @component_types.enum_for(:each)
  end
end
