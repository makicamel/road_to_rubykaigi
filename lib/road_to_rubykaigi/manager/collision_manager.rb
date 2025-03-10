module RoadToRubykaigi
  module Manager
    class CollisionManager
      def process
        {
          attack_bonus: [@attacks, @bonuses],
          attack_enemy: [@attacks, @enemies],
          player_bonus: [[@player], @bonuses],
          player_deadline: [[@player], [@deadline]],
          player_enemy: [[@player], @enemies],
        }.each do |type, pair|
          collided_pair = find_collided_pair(*pair)
          unless collided_pair.empty?
            EventDispatcher.publish(:collision, { type: type, pair: collided_pair })
          end
        end
      end

      private

      def initialize(attacks:, bonuses:, deadline:, enemies:, player:)
        @attacks = attacks
        @bonuses = bonuses
        @deadline = deadline
        @enemies = enemies
        @player = player
      end

      def find_collided_pair(entities, others)
        entities.map do |entity|
          found = others.find do |other|
            collided?(entity.bounding_box, other.bounding_box)
          end
          break [entity, found] if found
        end.compact
      end

      def collided?(box1, box2)
        !(
          box1[:x] + box1[:width] <= box2[:x] ||
          box1[:x] >= box2[:x] + box2[:width] ||
          box1[:y] + box1[:height] <= box2[:y] ||
          box1[:y] >= box2[:y] + box2[:height]
        )
      end
    end
  end
end
