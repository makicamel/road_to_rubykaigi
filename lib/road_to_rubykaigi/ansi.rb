module RoadToRubykaigi
  module ANSI
    CLEAR = "\e[2J"
    CURSOR_OFF = "\e[?25l"
    CURSOR_ON = "\e[?25h"
    HOME = "\e[H"
    RESET = "\e[0m"
    RED = "\e[31m"
    BACKGROUND_COLOR = "\e[48;5;230m"
    DEFAULT_TEXT_COLOR = "\e[38;5;238m"
    NULL = "\0"

    self.constants(false).each do |constant|
      ANSI.define_singleton_method(constant.to_s.downcase) {
        print const_get(constant)
      }
    end
  end
end
