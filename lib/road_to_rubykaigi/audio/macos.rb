require 'fiddle'
require 'fiddle/import'
require 'fiddle/types'

module RoadToRubykaigi
  module Audio
    module MacOS
      extend Fiddle::Importer
      dlopen '/System/Library/Frameworks/AVFoundation.framework/AVFoundation'
      dlload LibObjC = dlopen('/usr/lib/libobjc.A.dylib')
      include Fiddle::BasicTypes

      extern 'void* objc_getClass(const char*)'
      extern 'void* sel_registerName(const char*)'

      class << self
        def build_player(path)
          ns_string_path = objc_msgSend("NSString", "stringWithUTF8String:", path)
          ns_url = objc_msgSend("NSURL", "fileURLWithPath:", ns_string_path)
          error_pointer = 0 # Ignore errors
          initial_player = objc_msgSend("AVAudioPlayer", "alloc")
          objc_msgSend(initial_player, "initWithContentsOfURL:error:", ns_url, error_pointer)
        end

        def play(player)
          objc_msgSend(player, "stop") # Reset player
          objc_msgSend(player, "play")
        end

        private

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
    end
  end
end
