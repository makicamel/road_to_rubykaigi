module RoadToRubykaigi
  module Manager
    class CollisionManager
      def process
        collisions = CollisionDetector.new(attacks: @attacks, bonuses: @bonuses, deadline: @deadline, enemies: @enemies, player: @player).detect
        events = CollisionResolver.new(attacks: @attacks, bonuses: @bonuses, effects: @effects, enemies: @enemies, player: @player).resolve(collisions)
        if events.include?(:game_over)
          :game_over
        elsif events.include?(:bonus)
          :bonus
        end
      end

      private

      def initialize(map:, attacks:, bonuses:, deadline:, effects:, enemies:, player:)
        @map = map
        @attacks = attacks
        @bonuses = bonuses
        @deadline = deadline
        @effects = effects
        @enemies = enemies
        @player = player
      end
    end

    class CollisionDetector
      def detect
        {
          attack_bonus: [@attacks, @bonuses],
          attack_enemy: [@attacks, @enemies],
          player_bonus: [[@player], @bonuses],
          player_deadline: [[@player], [@deadline]],
          player_enemy: [[@player], @enemies],
        }.map do |type, pair|
          collided_pair = find_collided_pair(*pair)
          collided_pair.empty? ? nil : { type: type, pair: collided_pair }
        end.compact
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

    class CollisionResolver
      def resolve(collisions)
        events = []
        collisions.each do |collision|
          case collision[:type]
          when :attack_bonus
            attack, bonus = collision[:pair]
            @attacks.delete(attack)
            @bonuses.delete(bonus)
            @effects.heart(@player.x + @player.width - 1, @player.y)
            events << :bonus
          when :attack_enemy
            attack, enemy = collision[:pair]
            @attacks.delete(attack)
            @effects.note(@player.x + @player.width - 1, @player.y)
            @enemies.delete(enemy)
            events << :bonus
          when :player_bonus
            _, bonus = collision[:pair]
            @bonuses.delete(bonus)
            @effects.heart(@player.x + @player.width - 1, @player.y)
            events << :bonus
          when :player_deadline
            events << :game_over
          when :player_enemy
            _, enemy = collision[:pair]
            if @player.stompable?
              @effects.note(@player.x + @player.width - 1, @player.y)
              @enemies.delete(enemy)
              @player.jump
              events << :bonus
            else
              @effects.lightning(@player.x + @player.width - 1, @player.y)
              @enemies.delete(enemy)
              @player.stun
            end
          end
        end
        events
      end

      private

      def initialize(attacks:, bonuses:, effects:, enemies:, player:)
        @attacks = attacks
        @bonuses = bonuses
        @effects = effects
        @enemies = enemies
        @player = player
      end
    end
  end
end
