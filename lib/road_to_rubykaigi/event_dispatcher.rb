module RoadToRubykaigi
  module EventDispatcher
    class << self
      def subscribe(event, &block)
        subscribers[event] << block
      end

      def publish(event, *args)
        subscribers[event].each { |block| block.call(*args) }
      end

      private

      def subscribers
        @subscribers ||= Hash.new { |hash, key| hash[key] = [] }
      end
    end
  end

  class EventHander
    def self.subscribe(attacks:, bonuses:, effects:, enemies:, player:, game_manager:, score_board:)
      new(attacks: attacks, bonuses: bonuses, effects: effects, enemies: enemies, player: player, game_manager: game_manager, score_board: score_board).subscribe
    end

    def subscribe
      EventDispatcher.subscribe(:input) { |action| handle_input(action) }
      EventDispatcher.subscribe(:collision) { |collision| handle_collision(collision) }
      EventDispatcher.subscribe(:finish) { @game_manager.finish }
    end

    private

    def initialize(attacks:, bonuses:, effects:, enemies:, player:, game_manager:, score_board:)
      @attacks = attacks
      @bonuses = bonuses
      @effects = effects
      @enemies = enemies
      @player = player
      @game_manager = game_manager
      @score_board = score_board
    end

    def handle_input(action)
      return if @player.stunned?

      case action
      when :jump; @player.jump
      when :right; @player.right
      when :left; @player.left
      when :attack
        # @attacks.add(
        #   @player.x + @player.width,
        #   @player.y + 1,
        # )
      end
    end

    def handle_collision(collision)
      __send__(collision[:type], *collision[:pair])
    end

    def attack_bonus(attack, bonus)
      @attacks.delete(attack)
      @bonuses.delete(bonus)
      @effects.heart(@player.x + @player.width - 1, @player.y)
      @score_board.increment
    end

    def attack_enemy(attack, enemy)
      @attacks.delete(attack)
      @effects.note(@player.x + @player.width - 1, @player.y)
      @enemies.delete(enemy)
      @score_board.increment
    end

    def player_bonus(_, bonus)
      @bonuses.delete(bonus)
      @effects.heart(@player.x + @player.width - 1, @player.y)
      @score_board.increment
    end

    def player_deadline(*args)
      @game_manager.game_over
    end

    def player_enemy(_, enemy)
      if @player.stompable?
        @effects.note(@player.x + @player.width - 1, @player.y)
        @enemies.delete(enemy)
        @player.jump
        @score_board.increment
      else
        @effects.lightning(@player.x + @player.width - 1, @player.y)
        @enemies.delete(enemy)
        @player.stun
      end
    end
  end
end
