module RoadToRubykaigi
  class CollisionManager
    def process
      if player_meet_deadline?
        :game_over
      elsif process_player_bonus_collisions || process_attack_bonus_collisions
        :bonus
      end
    end

    private

    def initialize(player, bonuses, attacks, effects, deadline)
      @player = player
      @attacks = attacks
      @bonuses = bonuses
      @effects = effects
      @deadline = deadline
    end

    def player_meet_deadline?
      !!find_collision_item(@player, @deadline)
    end

    def process_player_bonus_collisions
      if (collided_item = find_collision_item(@player, @bonuses))
        @effects.heart(
          @player.x + @player.width - 1,
          @player.y,
        )
        @bonuses.delete(collided_item)
      end
    end

    def process_attack_bonus_collisions
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
