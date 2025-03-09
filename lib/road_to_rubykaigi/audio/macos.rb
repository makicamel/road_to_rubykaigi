require 'ffi'

module RoadToRubykaigi
  module Audio
    module CoreFoundation
      extend FFI::Library
      ffi_lib '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation'

      # CFStringCreateWithCString(CFAllocatorRef alloc, const char *cStr, CFStringEncoding encoding)
      attach_function :CFStringCreateWithCString, [:pointer, :string, :uint32], :pointer
      # CFURLCreateWithFileSystemPath(CFAllocatorRef alloc, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory)
      attach_function :CFURLCreateWithFileSystemPath, [:pointer, :pointer, :int, :bool], :pointer
      # CFRelease(CFTypeRef cf)
      attach_function :CFRelease, [:pointer], :void

      DefaultAllocator = FFI::Pointer::NULL
      POSIXPathStyle = 0
      UTF8Encoding = 0x08000100
    end

    module AudioToolbox
      extend FFI::Library
      ffi_lib '/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox'

      # OSStatus AudioServicesCreateSystemSoundID(CFURLRef inFileURL, SystemSoundID *outSystemSoundID)
      #   0 is success
      attach_function :AudioServicesCreateSystemSoundID, [:pointer, :pointer], :int
      # void AudioServicesPlaySystemSound(SystemSoundID inSystemSoundID)
      attach_function :AudioServicesPlaySystemSound, [:uint32], :void
      # OSStatus AudioServicesDisposeSystemSoundID(SystemSoundID inSystemSoundID)
      #   0 is success
      attach_function :AudioServicesDisposeSystemSoundID, [:uint32], :int
    end
  end
end
