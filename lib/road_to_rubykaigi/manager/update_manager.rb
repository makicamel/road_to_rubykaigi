module RoadToRubykaigi
  module Manager
    class UpdateManager
      def update(offset_x:)
        @enemies.each do |enemy|
          enemy.activate_with_offset(offset_x)
        end
        @effects.update
        @enemies.update
        @player.update
        @fireworks.update
        @player.enforce_boundary(@map, offset_x: offset_x)
        @attacks.enforce_boundary(@map, offset_x: offset_x)
      end

      private

      def initialize(map:, attacks:, effects:, enemies:, player:, fireworks:)
        @map = map
        @attacks = attacks
        @effects = effects
        @enemies = enemies
        @player = player
        @fireworks = fireworks
      end
    end
  end
end
