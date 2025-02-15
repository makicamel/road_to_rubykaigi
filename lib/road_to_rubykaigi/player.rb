module RoadToRubykaigi
    class Player
      AA = [
        "╭──────╮ ",
        "│｡・◡・│_◢◤",
        "╰ᜊ───ᜊ─╯ "
      ]

      def draw
        str = AA.map.with_index do |line, i|
          "\e[#{@y+i};#{@x}H" + line
        end.join("\n")
        print str
      end


      def move(dx, dy, map_width, map_height)
        new_x = @x + dx
        new_y = @y + dy
        @x = clamp(new_x, 2, map_width - width)
        @y = clamp(new_y, 2, map_height - height)
      end

      private

      def initialize(x = 10, y = 9)
        @x = x
        @y = y
      end

      def width
        @width ||= AA.first.size
      end

      def height
        @height ||= AA.size
      end

      def clamp(v, min, max)
        [[v, min].max, max].min
      end
    end
  end
