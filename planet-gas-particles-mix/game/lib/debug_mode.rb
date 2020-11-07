module DebugExtension
  class Debug
    def initialize(args)
      @args = args
      @active = false
      @debug_logs = []
      @last_debug_y = 720
    end

    def active?
      @active
    end

    def log(message, pos = nil)
      return if $gtk.production

      label_pos = pos || [0, @last_debug_y]
      @last_debug_y -= 20 unless pos
      @debug_logs << [label_pos.x, label_pos.y, message, 255, 255, 255].label
    end

    def tick
      return if $gtk.production

      @active = !@active if toggle_debug_mode?(@args.inputs)
      $gtk.reset if reset_game?(@args.inputs)

      log($gtk.current_framerate.to_i.to_s)
      log('DEBUG MODE') if @active

      @args.outputs.debug << @debug_logs
      @debug_logs.clear
      @last_debug_y = 720
    end

    private

    def toggle_debug_mode?(inputs)
      inputs.keyboard.key_up.d && inputs.keyboard.key_up.alt
    end

    def reset_game?(inputs)
      inputs.keyboard.key_up.r && inputs.keyboard.key_up.alt
    end
  end

  # Adds args.debug
  module Args
    def debug
      @debug ||= Debug.new(self)
    end
  end

  # Runs the debug tick
  module Runtime
    def tick_core
      @args.debug.tick
      super
    end
  end
end

GTK::Args.include DebugExtension::Args
GTK::Runtime.prepend DebugExtension::Runtime
