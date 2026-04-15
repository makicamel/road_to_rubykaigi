# Sample PicoRuby script for reading acceleration data from KXR94-2050 module
# and sending it via BLE UART.
#
# KXR94-2050 datasheet: https://akizukidenshi.com/goodsaffix/KXR94_2025_06_25.pdf
#   Sensitivity: Vdd / 5 (V/g)
#   Zero-g offset: Vdd / 2 (V)
#
# Flash this script to a Raspberry Pi Pico (2) W with PicoRuby.

require 'adc'
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
uart = BLE::UART.new(name: 'RtR')
uart.debug = true
blinker = Blinker.new

# uart.start block fires every BLE::POLLING_UNIT_MS (100ms). Taking multiple
# samples per block lifts the effective sampling rate above that polling rate.
# Targeting roughly 30Hz: 3 samples spaced by 30ms within each 100ms block.
SAMPLES_PER_BLOCK = 3
SAMPLE_INTERVAL_MS = 30

uart.start do
  SAMPLES_PER_BLOCK.times do |i|
    uart.puts(accelerometer.read)
    # puts("#{Time.now} #{accelerometer.read}")
    next if i == SAMPLES_PER_BLOCK - 1
    sleep_ms SAMPLE_INTERVAL_MS
  end

  blinker.mode = uart.connected? ? :slow : :fast
  blinker.tick
end
