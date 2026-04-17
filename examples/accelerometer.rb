# Sample PicoRuby script for reading acceleration data from KXR94-2050 module
# and sending it via BLE UART and hardware UART (serial).
#
# Data is always sent to both channels simultaneously:
#   - BLE UART: received by browser controller -> GameServer
#   - Hardware UART (GP0): received by USB-TTL cable -> SerialReader on the host
# Switch SERIAL=1 in .road_to_rubykaigi on the host side to choose which to use.
#
# Wiring (USB-TTL cable -> Pico W):
#   Cable RX  -> GP0 (UART0 TX)
#   Cable GND -> GND
#
# KXR94-2050 datasheet: https://akizukidenshi.com/goodsaffix/KXR94_2025_06_25.pdf
#   Sensitivity: Vdd / 5 (V/g)
#   Zero-g offset: Vdd / 2 (V)
#
# Flash this script to a Raspberry Pi Pico (2) W with PicoRuby.

require 'adc'
require 'uart'
require 'ble'
require 'ble-uart'

# Switch this to match the target board before flashing.
BOARD = :ble  # :ble or :serial

if BOARD == :ble
  # Sensor IC damaged: internal reference acts as ~2.3V despite VDD=3.3V.
  # Calibrated from x-axis ±1g voltages (1.47V / 0.65V).
  # Chip X/Y physically swapped on this board, so swap X/Y ADC pins.
  ZERO = 1.06
  SENSITIVITY = 0.41
  X_PIN, Y_PIN, Z_PIN = 27, 26, 28
else # :serial
  # Healthy sensor, datasheet values.
  ZERO = 3.3 / 2.0
  SENSITIVITY = 3.3 / 5.0
  X_PIN, Y_PIN, Z_PIN = 26, 27, 28
end

class Accelerometer
  def initialize
    GPIO.new(19, GPIO::OUT).write(1)
    sleep 0.5

    @ax = ADC.new(X_PIN)
    @ay = ADC.new(Y_PIN)
    @az = ADC.new(Z_PIN)
  end

  def read
    x = to_g(@ax.read_voltage)
    y = to_g(@ay.read_voltage)
    z = to_g(@az.read_voltage)
    "x=#{x.round(5)},y=#{y.round(5)},z=#{z.round(5)}"
  end

  # private

  def to_g(voltage)
    (voltage - ZERO) / SENSITIVITY
  end
end

class Blinker
  LED_PIN = CYW43::GPIO::LED_PIN
  FAST_INTERVAL_MS = 200
  SLOW_INTERVAL_MS = 500
  INTERVALS = {
    fast: FAST_INTERVAL_MS / BLE::POLLING_UNIT_MS,
    slow: SLOW_INTERVAL_MS / BLE::POLLING_UNIT_MS,
  }

  attr_writer :mode

  def initialize
    @led = CYW43::GPIO.new(LED_PIN)
    @on = false
    @tick = 0
    @mode = :fast
  end

  def tick
    @tick += 1
    return if @tick < INTERVALS[@mode]

    @tick = 0
    @on = !@on
    @led.write(@on ? 1 : 0)
  end
end

accelerometer = Accelerometer.new
serial = UART.new(unit: :RP2040_UART0, txd_pin: 0, baudrate: 115200)
ble_uart = BLE::UART.new(name: 'RtR')
ble_uart.debug = true
blinker = Blinker.new

# BLE::UART#start loop period = user_block duration + BLE::POLLING_UNIT_MS (100ms).
# Measured per-sample processing ≈ 4-5ms; packing 5 samples per block hits ~30Hz:
#   user_block ≈ 4 * 5ms (inter-sample sleep) + 5 * ~4.5ms ≈ 42ms
#   loop period ≈ 42 + 100 = 142ms → 5 / 0.142 ≈ 35Hz nominal, ~30Hz realistic
SAMPLES_PER_BLOCK = 5
SAMPLE_INTERVAL_MS = 5

ble_uart.start do
  if ble_uart.connected?
    SAMPLES_PER_BLOCK.times do |i|
      data = accelerometer.read
      ble_uart.puts(data)
      serial.puts(data)
      next if i == SAMPLES_PER_BLOCK - 1
      sleep_ms SAMPLE_INTERVAL_MS
    end
  else
    # Skip sleep_ms during pre-connection: it appears to delay BLE setup,
    # making BLE::UART.new on the JS side take longer to return.
    SAMPLES_PER_BLOCK.times do
      data = accelerometer.read
      serial.puts(data)
    end
  end

  blinker.mode = ble_uart.connected? ? :slow : :fast
  blinker.tick
end
