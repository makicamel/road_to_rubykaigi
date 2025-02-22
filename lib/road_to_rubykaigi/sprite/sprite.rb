module RoadToRubykaigi
  module Sprite
    class Sprite
      def characters
        yield.map do |character|
          fullwidth?(character) ? [character, ANSI::NULL] : character
        end.flatten
      end

      private

      def fullwidth?(character)
        code = character.ord
        (0x1F300..0x1F5FF).cover?(code) ||
          (0x1F600..0x1F64F).cover?(code) ||
          (0x1F680..0x1F6FF).cover?(code) ||
          (0x1F700..0x1F77F).cover?(code)
      end
    end
  end
end
