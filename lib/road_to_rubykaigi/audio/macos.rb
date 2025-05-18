require 'fiddle'
require 'fiddle/import'
require 'fiddle/types'

module RoadToRubykaigi
  module Audio
    class MacOS
      extend Fiddle::Importer
      dlopen '/System/Library/Frameworks/AVFoundation.framework/AVFoundation'
      dlload LibObjC = dlopen('/usr/lib/libobjc.A.dylib')
      include Fiddle::BasicTypes

      class << self
        def build_player(path)
          ns_string_path = objc_msgSend("NSString", "stringWithUTF8String:", path)
          ns_url = objc_msgSend("NSURL", "fileURLWithPath:", ns_string_path)
          error_pointer = 0 # Ignore errors
          initial_player = objc_msgSend("AVAudioPlayer", "alloc")
          new(
            objc_msgSend(initial_player, "initWithContentsOfURL:error:", ns_url, error_pointer)
          )
        end

        def objc_getClass(name)
          @objc_getClass ||= Fiddle::Function.new(
            LibObjC["objc_getClass"],
            [Fiddle::TYPE_VOIDP],
            Fiddle::TYPE_VOIDP,
          )
          @objc_getClass.call(name)
        end

        def sel_registerName(register_name)
          @sel_registerName ||= Fiddle::Function.new(
            LibObjC["sel_registerName"],
            [Fiddle::TYPE_VOIDP],
            Fiddle::TYPE_VOIDP,
          )
          @sel_registerName.call(register_name)
        end

        def objc_msgSend(klass_or_klass_name, selector_name, *args)
          klass = klass_or_klass_name.is_a?(String) ? objc_getClass(klass_or_klass_name) : klass_or_klass_name
          func = Fiddle::Function.new(
            LibObjC["objc_msgSend"],
            [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP] + args.map { Fiddle::TYPE_VOIDP },
            Fiddle::TYPE_VOIDP,
          )
          func.call(
            klass,
            sel_registerName(selector_name),
            *args,
          )
        end
      end

      def play
        objc_msgSend(@player, "stop") # Reset player
        objc_msgSend(@player, "play")
      end

      def playing?
        @func ||= Fiddle::Function.new(
          LibObjC["objc_msgSend"],
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
          Fiddle::TYPE_INT, # Type conversion from bool to int
        )
        result = @func.call(@player, sel_registerName("isPlaying"))
        result != 0
      end

      private

      def initialize(player)
        @player = player
      end

      def objc_msgSend(klass_or_klass_name, selector_name, *args)
        self.class.objc_msgSend(klass_or_klass_name, selector_name, *args)
      end

      def sel_registerName(selector_name)
        self.class.sel_registerName(selector_name)
      end
    end
  end
end
