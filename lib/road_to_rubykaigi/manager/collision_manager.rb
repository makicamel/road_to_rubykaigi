module RoadToRubykaigi
  module Manager
    class CollisionManager
      def process
        player_meet_enemy
        if player_meet_deadline?
          :game_over
        elsif player_meet_bonus || attack_hit_bonus || attack_hit_enemy
          :bonus
        end
      end

      private

      def initialize(foreground)
        @player, @deadline, @bonuses, @enemies, @attacks, @effects = foreground.layers
      end

      def player_meet_deadline?
        !!find_collision_item(@player, @deadline)
      end

      def player_meet_bonus
        if (collided_item = find_collision_item(@player, @bonuses))
          @effects.heart(
            @player.x + @player.width - 1,
            @player.y,
          )
          @bonuses.delete(collided_item)
        end
      end

      def attack_hit_bonus
        collided = @attacks.dup.select do |attack|
          if (collided_item = find_collision_item(attack, @bonuses))
            @effects.heart(
              @player.x + @player.width - 1,
              @player.y,
            )
            @bonuses.delete(collided_item)
            @attacks.delete(attack)
          end
        end.empty?
        !collided
      end

      def attack_hit_enemy
        collided = @attacks.dup.select do |attack|
          if (collided_item = find_collision_item(attack, @enemies))
            @effects.heart(
              @player.x + @player.width - 1,
              @player.y,
            )
            @enemies.delete(collided_item)
            @attacks.delete(attack)
          end
        end.empty?
        !collided
      end

      def player_meet_enemy
        if (collided_item = find_collision_item(@player, @enemies))
          @effects.lightning(
            @player.x + @player.width - 1,
            @player.y,
          )
          @enemies.delete(collided_item)
          @player.stun
        end
      end

      def find_collision_item(entity, others)
        others.find do |other|
          collided?(entity.bounding_box, other.bounding_box)
        end
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
