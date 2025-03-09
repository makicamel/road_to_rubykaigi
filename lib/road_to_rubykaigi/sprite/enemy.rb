require "forwardable"

module RoadToRubykaigi
  module Sprite
    class Enemies
      extend Forwardable
      def_delegators :@enemies, :to_a, :find, :delete, :each
      ENEMIES_DATA = {
        FixedPatrol: [
          { x: 55, y: 6, left_bound: 0, right_bound: 0, speed: 0, character: :ladybug },
          { x: 125, y: 8, left_bound: 0, right_bound: 0, speed: 0, character: :ladybug },
          { x: 293, y: 23, left_bound: 0, right_bound: 0, speed: 0, character: :spider },
        ],
        HorizontalPatrol: [
          { x: 123, y: 26, left_bound: 114, right_bound: 123, speed: 1.5, character: :bee },
          { x: 171, y: 26, left_bound: 162, right_bound: 171, speed: 1.5, character: :bee },
          { x: 278, y: 15, left_bound: 270, right_bound: 278, speed: 1.5, character: :bug },
          { x: 291, y: 15, left_bound: 283, right_bound: 291, speed: 1.5, character: :bug },
          { x: 302, y: 15, left_bound: 297, right_bound: 302, speed: 1.5, character: :bug },
        ],
        ScreenEntryPatrol: [
          { x: 63, y: 27, left_bound: 0, right_bound: 63, speed: 4.0, character: :bug },
          { x: 76, y: 27, left_bound: 0, right_bound: 76, speed: 4.0, character: :bug },
          { x: 87, y: 27, left_bound: 0, right_bound: 76, speed: 4.0, character: :bug },
          { x: 221, y: 23, left_bound: 0, right_bound: 151, speed: 6.0, character: :bee },
          { x: 240, y: 19, left_bound: 0, right_bound: 170, speed: 6.0, character: :bee },
          { x: 256, y: 16, left_bound: 0, right_bound: 186, speed: 6.0, character: :bee },
        ],
      }

      def build_buffer(offset_x:)
        buffer = Array.new(Map::VIEWPORT_HEIGHT) { Array.new(Map::VIEWPORT_WIDTH) { "" } }
        @enemies.each do |enemy|
          bounding_box = enemy.bounding_box
          relative_x = bounding_box[:x] - offset_x - 1
          relative_y = bounding_box[:y] - 1
          next if relative_x < 1
          enemy.characters.each_with_index do |character, j|
            next if relative_x + j >= Map::VIEWPORT_WIDTH - 1
            buffer[relative_y][relative_x+j] = character
          end
        end
        buffer
      end

      def simulate_physics
        if activated?
          @enemies.each(&:move)
        end
      end

      def update
        unless activated?
          @enemies.each(&:reset_last_update_time)
        end
      end

      def activate
        @waiting = false
      end

      private

      def initialize
        @enemies = ENEMIES_DATA.map do |key, enemies|
          strategy = RoadToRubykaigi::Sprite.const_get("#{key}Strategy")
          enemies.map do |enemy|
            Enemy.new(
              enemy[:x],
              enemy[:y],
              enemy[:character],
              strategy.new(
                left_bound: enemy[:left_bound],
                right_bound: enemy[:right_bound],
                speed: enemy[:speed],
              ),
            )
          end
        end.flatten
        @waiting = true
      end

      def activated?
        !@waiting
      end
    end

    class Enemy < Sprite
      CHARACTER = {
        bee: "🐝",
        bug: "🐛",
        ladybug: "🐞",
        spider: "🕷️",
      }
      RIGHT = 1
      LEFT = -1
      attr_accessor :x
      attr_reader :y, :direction

      def bounding_box
        { x: @x, y: @y, width: width, height: height }
      end

      def characters
        super { [CHARACTER[@character]] }
      end

      def move
        elapsed_time = Time.now - @last_update_time
        @last_update_time = Time.now
        @strategy.move(self, elapsed_time)
      end

      def reset_last_update_time
        @last_update_time = Time.now
      end

      def width
        2
      end

      def height
        1
      end

      def reverse_direction
        @direction *= -1
      end

      def activate_with_offset(offset_x)
        if !@active && @x <= (offset_x + Map::VIEWPORT_WIDTH)
          @active = true
        end
      end

      def active?
        @active
      end

      private

      def initialize(x, y, character, strategy)
        @x = x
        @y = y
        @character = character
        @direction = LEFT
        @strategy = strategy
        @active = !strategy.is_a?(ScreenEntryPatrolStrategy)
        @last_update_time = Time.now
      end
    end

    class PatrolStrategy
      def initialize(left_bound:, right_bound:, speed:)
        @left_bound = left_bound
        @right_bound = right_bound
        @speed = speed
      end

      def move(enemy, elapsed_time)
      end
    end

    class FixedPatrolStrategy < PatrolStrategy
    end

    class HorizontalPatrolStrategy < PatrolStrategy
      def move(enemy, elapsed_time)
        enemy.x += @speed * elapsed_time * enemy.direction
        enemy.x = enemy.x.clamp(@left_bound, @right_bound)
        enemy.reverse_direction if enemy.x == @left_bound || enemy.x == @right_bound
      end
    end

    class ScreenEntryPatrolStrategy < PatrolStrategy
      def move(enemy, elapsed_time)
        return unless enemy.active?
        enemy.x += @speed * elapsed_time * enemy.direction
      end
    end
  end
end
