module RoadToRubykaigi
  module Manager
    class CollisionManager
      def process
        event = [player_meet_enemy] # player must hit enemy before land
        player_fall
        player_land

        event += [
          player_meet_deadline,
          player_meet_bonus,
          attack_hit_bonus,
          attack_hit_enemy,
        ]
        if event.include?(:game_over)
          :game_over
        elsif event.include?(:bonus)
          :bonus
        end
      end

      private

      def initialize(background, foreground)
        @map = background
        @player, @deadline, @bonuses, @enemies, @attacks, @effects = foreground.layers
      end

      def player_fall
        bounding_box = @player.bounding_box
        foot_y = bounding_box[:y] + bounding_box[:height]
        center_x = bounding_box[:x] + bounding_box[:width] / 2.0
        if @map.passable_at?(center_x, foot_y + 1)
          @player.fall
        end
      end

      def player_land
        bounding_box = @player.bounding_box
        foot_y = bounding_box[:y] + bounding_box[:height]
        foot_y = foot_y.clamp(bounding_box[:height], RoadToRubykaigi::Sprite::Player::BASE_Y)
        (bounding_box[:x]...(bounding_box[:x] + bounding_box[:width])).each do |col|
          unless @map.passable_at?(col, foot_y)
            break @player.land(foot_y)
          end
        end
      end

      # @returns [:game_over, Nil]
      def player_meet_deadline
        find_collision_item(@player, @deadline) && :game_over
      end

      def player_meet_bonus
        if (collided_item = find_collision_item(@player, @bonuses))
          @effects.heart(
            @player.x + @player.width - 1,
            @player.y,
          )
          @bonuses.delete(collided_item)
          :bonus
        end
      end

      # @returns [:bonus, false]
      def attack_hit_bonus
        collided = !@attacks.dup.select do |attack|
          if (collided_item = find_collision_item(attack, @bonuses))
            @effects.heart(
              @player.x + @player.width - 1,
              @player.y,
            )
            @bonuses.delete(collided_item)
            @attacks.delete(attack)
          end
        end.empty?
        collided && :bonus
      end

      # @returns [:bonus, Nil]
      def attack_hit_enemy
        collided = !@attacks.dup.select do |attack|
          if (collided_item = find_collision_item(attack, @enemies))
            @effects.heart(
              @player.x + @player.width - 1,
              @player.y,
            )
            @enemies.delete(collided_item)
            @attacks.delete(attack)
          end
        end.empty?
        collided && :bonus
      end

      # @returns [:bonus, Nil]
      def player_meet_enemy
        if (collided_item = find_collision_item(@player, @enemies))
          if @player.vy > 0
            @effects.heart(
              @player.x + @player.width - 1,
              @player.y,
            )
            @enemies.delete(collided_item)
            @player.vy = @player.class::JUMP_INITIAL_VELOCITY
            :bonus
          else
            @effects.lightning(
              @player.x + @player.width - 1,
              @player.y,
            )
            @enemies.delete(collided_item)
            @player.stun
          end
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
