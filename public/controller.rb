require 'js'

class Controller
  LOCAL_ENDPOINT = 'http://127.0.0.1:2026/road_to_rubykaigi'
  POLL_INTERVAL_MS = 1000 / 60 # Manager::GameManager::FRAME_RATE

  def initialize
    bind_events
    log('[*] Ready. Click Connect to pair with a BLE UART device.')
  end

  def bind_events
    element('btn-connect').addEventListener('click') { |_event| connect }
    element('btn-disconnect').addEventListener('click') { |_event| disconnect }
    JS.global.addEventListener('beforeunload') { |_event| force_disconnect }
  end

  def force_disconnect
    return unless @uart
    @uart.device.js_device[:gatt].disconnect
  rescue
    # best effort: ignore any errors during page unload
  end

  def element(id)
    @document ||= JS.document
    @document.getElementById(id)
  end

  def log(message)
    log_element = element('log')
    log_element.textContent = "#{log_element.textContent}#{message}\n"
    log_element.scrollTop = log_element.scrollHeight
  end

  def connect
    prefix = element('device-name-prefix').value
    svc = element('svc-uuid').value.to_s
    tx = element('tx-uuid').value.to_s
    rx = element('rx-uuid').value.to_s
    log("[*] Connecting UART (svc=#{svc} tx=#{tx} rx=#{rx} prefix=#{prefix})...")
    begin
      @uart = JS::BLE::UART.new(service_uuid: svc, tx_uuid: tx, rx_uuid: rx, name_prefix: prefix)
      log("[+] Connected to: #{@uart.device.name}")
      set_ui(true)
      start_auto_read
    rescue => e
      log("[-] Error: #{e.message}")
    end
  end

  def disconnect
    stop_auto_read

    return unless @uart
    @uart.close
    @uart = nil
    log('[*] Disconnected')
    set_ui(false)
  end

  def set_ui(connected)
    if connected
      element('status').textContent = 'Connected'
      element('status').className = 'connected'
      element('btn-connect').setAttribute('disabled', 'true')
      element('btn-disconnect').removeAttribute('disabled')
    else
      element('status').textContent = 'Disconnected'
      element('status').className = 'disconnected'
      element('btn-connect').removeAttribute('disabled')
      element('btn-disconnect').setAttribute('disabled', 'true')
    end
  end

  def start_auto_read
    @auto_read = true
    schedule_auto_read
    log('[*] Auto receive started')
  end

  def schedule_auto_read
    return unless @auto_read

    @read_timer = JS.global.setTimeout(POLL_INTERVAL_MS) do
      poll_uart
      schedule_auto_read
    end
  end

  def stop_auto_read
    @auto_read = false

    if @read_timer
      JS.global.clearTimeout(@read_timer)
      @read_timer = nil
    end
  end

  def poll_uart
    data = @uart.read_nonblock(256)
    return if data.nil? || data.empty?

    @line_buffer ||= ''
    @line_buffer << data

    while (idx = @line_buffer.index("\n"))
      line = @line_buffer.slice!(0..idx).strip
      log("[DATA] #{line}")
      send_data(line)
    end
  end

  def send_data(line)
    query = line.gsub(',', '&')
    url = "#{LOCAL_ENDPOINT}?#{query}"

    JS.global.fetch(url) do |response|
      log("[HTTP] GET #{response.status}")
    end
  end
end

Controller.new
