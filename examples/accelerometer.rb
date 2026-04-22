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

ZERO = 3.3 / 2.0
SENSITIVITY = 3.3 / 5.0
# Sensor axes in chip-native frame (both boards mount the chip the same way
# relative to the body):
#   chip X = vertical (up/down along gravity)
#   chip Y = horizontal (lateral)
#   chip Z = body front-back
# Emitted stream uses a rotated frame where Z = up, so at rest both boards
# emit (x=0, y=0, z=+1). Chip X reads -1g at rest, so Z_SIGN=-1 flips it.
if BOARD == :ble
  # Chip X/Y physically swapped on this board: pin 26 reads chip Y, pin 27
  # reads chip X.
  X_PIN, Y_PIN, Z_PIN = 26, 28, 27
else # :serial
  # Straight pin-to-chip mapping: pin 26=chip X, 27=chip Y, 28=chip Z.
  X_PIN, Y_PIN, Z_PIN = 27, 28, 26
end
X_SIGN, Y_SIGN, Z_SIGN = 1, 1, -1

class Accelerometer
  def initialize
    GPIO.new(19, GPIO::OUT).write(1)
    sleep 0.5

    @ax = ADC.new(X_PIN)
    @ay = ADC.new(Y_PIN)
    @az = ADC.new(Z_PIN)
  end

  def read
    x = to_g(@ax.read_voltage) * X_SIGN
    y = to_g(@ay.read_voltage) * Y_SIGN
    z = to_g(@az.read_voltage) * Z_SIGN
    bootsel = Machine.bootsel_pressed? ? 1 : 0
    "x=#{x.round(5)},y=#{y.round(5)},z=#{z.round(5)},b=#{bootsel}"
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
  TICK_INTERVAL_MS = BLE::POLLING_UNIT_MS / BLE::UART::USER_BLOCK_CALL_COUNT_PER_POLL
  INTERVALS = {
    fast: FAST_INTERVAL_MS / TICK_INTERVAL_MS,
    slow: SLOW_INTERVAL_MS / TICK_INTERVAL_MS,
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

# The BLE connection interval (negotiated by the central) caps the notification rate,
# the sensor produces faster than a single-sample-per-notify stream can be delivered.
# Batching keeps the effective sample rate while staying under the notification throughput ceiling.
BLE_BATCH_SIZE = 2
SAMPLE_SEPARATOR = '|'

ble_batch = []

# BLE::UART#start calls this block USER_BLOCK_CALL_COUNT_PER_POLL times per BLE
# polling cycle (every POLLING_UNIT_MS / USER_BLOCK_CALL_COUNT_PER_POLL ≈ 20ms).
# Send one sample per call — no inner loop, no sleep_ms here.
ble_uart.start do
  data = accelerometer.read
  if ble_uart.connected?
    ble_batch << data
    if ble_batch.size >= BLE_BATCH_SIZE
      ble_uart.puts(ble_batch.join(SAMPLE_SEPARATOR))
      ble_batch.clear
    end
  else
    serial.puts(data)
  end

  blinker.mode = ble_uart.connected? ? :slow : :fast
  blinker.tick
end
