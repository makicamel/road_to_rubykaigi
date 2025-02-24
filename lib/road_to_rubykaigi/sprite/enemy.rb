require "forwardable"

module RoadToRubykaigi
  module Sprite
    class Enemies
      extend Forwardable
      def_delegators :@enemies, :to_a, :find, :delete
      ENEMIES_DATA = [
        { x: 30, y: 26, left_bound: 25, right_bound: 35, speed: 2.0 },
        { x: 60, y: 26, left_bound: 55, right_bound: 65, speed: 1.5 },
        { x: 90, y: 26, left_bound: 85, right_bound: 95, speed: 2.5 },
      ]

      def build_buffer(offset_x:)
        buffer = Array.new(Map::VIEWPORT_HEIGHT) { Array.new(Map::VIEWPORT_WIDTH) { "" } }
        @enemies.each do |enemy|
          bounding_box = enemy.bounding_box
          relative_x = bounding_box[:x] - offset_x - 1
          relative_y = bounding_box[:y] - 1
          next if relative_x < 1
          enemy.characters.each_with_index do |chara, j|
            buffer[relative_y][relative_x+j] = chara
          end
        end
        buffer
      end

      def update
        @enemies.each(&:update)
      end

      private

      def initialize
        @enemies = ENEMIES_DATA.map do |enemy|
          Bug.new(
            enemy[:x],
            enemy[:y],
            HorizontalPatrolStrategy.new(
              left_bound: enemy[:left_bound],
              right_bound: enemy[:right_bound],
              speed: enemy[:speed],
            ),
          )
        end
      end
    end

    class Enemy < Sprite
      RIGHT = 1
      LEFT  = -1
      attr_accessor :x
      attr_reader :y, :direction

      def bounding_box
        { x: @x, y: @y, width: width, height: height }
      end

      def characters
        super { [self.class::CHARACTER] }
      end

      def update
        elapsed_time = Time.now - @last_update_time
        @last_update_time = Time.now
        @strategy.update(self, elapsed_time)
      end

      def width
        self.class::WIDTH
      end

      def height
        self.class::HEIGHT
      end

      def reverse_direction
        @direction *= -1
      end

      private

      def initialize(x, y, strategy)
        @x = x
        @y = y
        @direction = LEFT
        @strategy = strategy
        @last_update_time = Time.now
      end
    end

    class Bug < Enemy
      CHARACTER = ["🐛", "🐝"].sample
      WIDTH = 2
      HEIGHT = 1
    end

    class HorizontalPatrolStrategy
      def initialize(left_bound:, right_bound:, speed:)
        @left_bound = left_bound
        @right_bound = right_bound
        @speed = speed
      end

      def update(enemy, elapsed_time)
        enemy.x += @speed * elapsed_time * enemy.direction
        enemy.x = enemy.x.clamp(@left_bound, @right_bound)
        enemy.reverse_direction if enemy.x == @left_bound || enemy.x == @right_bound
      end
    end
  end
end
