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

class Accelerometer
  VDD = 3.3
  ZERO = VDD / 2.0 # zero-g output voltage
  SENSITIVITY = VDD / 5.0 # output voltage per 1g

  def initialize
    GPIO.new(19, GPIO::OUT).write(1)
    sleep 0.5

    @ax = ADC.new(26)
    @ay = ADC.new(27)
    @az = ADC.new(28)
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

# uart.start block fires every BLE::POLLING_UNIT_MS (100ms). Taking multiple
# samples per block lifts the effective sampling rate above that polling rate.
# Targeting roughly 30Hz: 3 samples spaced by 30ms within each 100ms block.
SAMPLES_PER_BLOCK = 3
SAMPLE_INTERVAL_MS = 30

ble_uart.start do
  SAMPLES_PER_BLOCK.times do |i|
    ble_uart.puts(accelerometer.read)
    serial.puts(data)
    # puts("#{Time.now} #{accelerometer.read}")
    next if i == SAMPLES_PER_BLOCK - 1
    sleep_ms SAMPLE_INTERVAL_MS
  end

  blinker.mode = ble_uart.connected? ? :slow : :fast
  blinker.tick
end
