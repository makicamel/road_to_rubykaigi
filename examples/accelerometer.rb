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
  INTERVAL_MS = 100

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

accelerometer = Accelerometer.new
uart = BLE::UART.new(name: 'RtR')
uart.debug = true

uart.start do
  uart.puts(accelerometer.read)
  # puts("#{Time.now} #{accelerometer.read}")
end
