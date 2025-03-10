module RoadToRubykaigi
  module Manager
    class PhysicsEngine
      def simulate
        @attacks.simulate_physics
        @deadline.simulate_physics
        @enemies.simulate_physics
        @player.simulate_physics
      end

      private

      def initialize(attacks:, deadline:, enemies:, player:)
        @attacks = attacks
        @deadline = deadline
        @enemies = enemies
        @player = player
      end
    end
  end
end
