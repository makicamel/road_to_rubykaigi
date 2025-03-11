require 'fiddle'
require 'fiddle/import'
require 'fiddle/types'

module RoadToRubykaigi
  module Audio
    module CoreFoundation
      extend Fiddle::Importer
      dlload '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation'
      include Fiddle::BasicTypes

      # CFStringCreateWithCString(CFAllocatorRef alloc, const char *cStr, CFStringEncoding encoding)
      extern 'void* CFStringCreateWithCString(void*, const char*, unsigned int)'
      # CFURLCreateWithFileSystemPath(CFAllocatorRef alloc, CFStringRef filePath, CFURLPathStyle pathStyle, int isDirectory)
      extern 'void* CFURLCreateWithFileSystemPath(void*, void*, int, int)'
      # CFRelease(CFTypeRef cf)
      extern 'void CFRelease(void*)'

      DefaultAllocator = 0
      POSIXPathStyle = 0
      UTF8Encoding = 0x08000100
    end

    module AudioToolbox
      extend Fiddle::Importer
      dlload '/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox'
      include Fiddle::BasicTypes

      # OSStatus AudioServicesCreateSystemSoundID(CFURLRef inFileURL, SystemSoundID *outSystemSoundID)
      #   0 is success
      extern 'int AudioServicesCreateSystemSoundID(void*, void*)'
      # void AudioServicesPlaySystemSound(SystemSoundID inSystemSoundID)
      extern 'void AudioServicesPlaySystemSound(unsigned int)'
      # OSStatus AudioServicesDisposeSystemSoundID(SystemSoundID inSystemSoundID)
      #   0 is success
      extern 'int AudioServicesDisposeSystemSoundID(unsigned int)'
    end
  end
end
