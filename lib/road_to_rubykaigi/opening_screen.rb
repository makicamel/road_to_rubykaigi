module RoadToRubykaigi
  class OpeningScreen
    WIDTH = 10
    OFFSET = 30
    DELAY = 0.75
    LOGO =<<~LOGO
      ╔═══════╗
      ║       ║
      ║       ║                                ║
      ║       ║                                ║
      ╠═════╦═╝  ╔═══════╗  ╔═══════║   ╔══════╣
      ║     ╚═╗  ║       ║  ║       ║  ╔╝      ║    ══╬══  ╔═══╗
      ║       ║  ║       ║  ║       ║  ║       ║      ║    ║   ║
      ║       ║  ╚═══════╝  ╚═══════║  ╚═══════╝      ║    ╚═══╝

      ╔═══════╗                                   ║       ║
      ║       ║                                   ║       ║
      ║       ║             ║          ║       ║  ║       ║                ╔═══════║
      ║       ║             ║          ║       ║  ║       ║             ║  ║       ║  ║
      ╠═════╦═╝  ║       ║  ╠══════╗   ║       ║  ╠═════╦═╝  ╔═══════║     ║       ║
      ║     ╚═╗  ║       ║  ║      ╚╗  ╚═══════╣  ║     ╚═╗  ║       ║  ║  ╚═══════╣  ║
      ║       ║  ║       ║  ║       ║          ║  ║       ║  ║       ║  ║          ║  ║
      ║       ║  ╚═══════║  ╚═══════╝  ════════╝  ║       ║  ╚═══════║  ║  ════════╝  ║
    LOGO
    PLAYER =<<~PLAYER
      ╭──────╮
      │｡・◡・│_◢◤
      ╰ᜊ───ᜊ─╯
    PLAYER
    VERSION_ROW = 25

    def display
      loop do
        ANSI.clear
        render
        $stdin.raw do
          if handle_input == :SELECTED
            item = menu_items[@menu_index]
            case item
            when :calibrate
              CalibrationScreen.new.display
            when :input_source
              Config.cycle_input_source
              @menu_items = nil
              @menu_index = menu_items.index(:input_source) || 0
            else
              return item
            end
          end
          move_player
          sleep Manager::GameManager::FRAME_RATE
        end
      end
    end

    private

    def initialize
      @player_x = 0
      @direction = 1
      @last_move_time = Time.now
      @menu_index = 0
    end

    def menu_items
      return @menu_items if @menu_items
      @menu_items = RoadToRubykaigi::VERSIONS + [:input_source]
      @menu_items = @menu_items + [:calibrate] if Config.external_input?
      @menu_items
    end

    INPUT_SOURCE_LABELS = { ble: 'BLE', serial: 'Serial', nil => 'Keyboard' }.freeze

    def render
      puts [
        "\e[6;1H",
        LOGO,
        PLAYER.lines.map.with_index do |line, i|
          "\e[#{i+1};#{@player_x+OFFSET}H" + line
        end.join,
        "\e[4;1H",
        " Press Space to start...",
      ]
      menu_items.each_with_index do |item, i|
        cursor = i == @menu_index ? " -> " : "    "
        row_offset = case item
                     when :input_source, :calibrate then 1
                     else 0
                     end
        label =
          case item
          when :calibrate then 'Calibrate sensor'
          when :input_source then "Input: #{INPUT_SOURCE_LABELS[Config.input_source]}"
          else "ver. #{RoadToRubykaigi::VERSIONS[i]}"
          end
        print "\e[#{VERSION_ROW + i + row_offset};1H#{cursor}#{label}"
      end
    end

    def handle_input
      case $stdin.read_nonblock(3, exception: false)
      when ANSI::UP
        @menu_index = (@menu_index - 1) % menu_items.size
      when ANSI::DOWN
        @menu_index = (@menu_index + 1) % menu_items.size
      when " "
        :SELECTED
      when ANSI::ETX
        raise Interrupt
      end
    end

    def move_player
      if Time.now - @last_move_time >= DELAY
        @player_x += @direction
        if @player_x >= WIDTH || @player_x <= 0
          @direction = -@direction
        end
        @last_move_time = Time.now
      end
    end
  end
end
