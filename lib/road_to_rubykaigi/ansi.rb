module RoadToRubykaigi
  module ANSI
    CLEAR = "\e[2J"
    CURSOR_OFF = "\e[?25l"
    CURSOR_ON = "\e[?25h"
    HOME = "\e[H"

    self.constants(false).each do |constant|
      ANSI.define_singleton_method(constant.to_s.downcase) {
        print const_get(constant)
      }
    end
  end
end
