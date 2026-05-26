require 'js'

class Controller
  LOCAL_ENDPOINT = 'http://127.0.0.1:2026/road_to_rubykaigi'
  POLL_INTERVAL_MS = 1000 / 60 # Manager::GameManager::FRAME_RATE
  SAMPLE_SEPARATOR = '|'
  MAX_RECONNECT_ATTEMPTS = 5
  RECONNECT_DELAY_MS = 1500

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
    return unless @device
    @device.js_device[:gatt].disconnect
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
    @svc_uuid = element('svc-uuid').value.to_s
    @tx_uuid = element('tx-uuid').value.to_s
    @rx_uuid = element('rx-uuid').value.to_s
    log("[*] Connecting (svc=#{@svc_uuid} rx=#{@rx_uuid} prefix=#{prefix})...")
    begin
      @device = JS::BLE::GATT.request_device(
        name_prefix: prefix,
        optional_services: [@svc_uuid]
      )
      @device.js_device.addEventListener('gattserverdisconnected') { |_event| handle_gatt_disconnect }
      open_rx_characteristic
      log("[+] Connected to: #{@device.name}")
      @user_initiated_disconnect = false
      set_ui(true)
      start_auto_read
    rescue => e
      log("[-] Error: #{e.message}")
      @device = nil
    end
  end

  def open_rx_characteristic
    @line_buffer = ''
    log("[debug] before connect!")
    server = @device.connect
    log("[debug] before service")
    service = server.service(@svc_uuid)
    log("[debug] before characteristic")
    @rx_char = service.characteristic(@rx_uuid)
    log("[debug] before on_change")
    @rx_char.on_change { |data| @line_buffer << data }
    log("[debug] before start_notify")
    @rx_char.start_notify
    log("[debug] done")
  end

  def handle_gatt_disconnect
    stop_auto_read
    @rx_char = nil

    if @user_initiated_disconnect || @device.nil?
      log('[!] Device disconnected (GATT)')
      set_ui(false)
    else
      log('[!] Device disconnected (GATT) -- will try to reconnect')
      schedule_reconnect(1)
    end
  end

  def schedule_reconnect(attempt)
    set_status("Reconnecting... (attempt #{attempt}/#{MAX_RECONNECT_ATTEMPTS})")
    JS.global.setTimeout(RECONNECT_DELAY_MS) { attempt_reconnect(attempt) }
  end

  def attempt_reconnect(attempt)
    return unless @device
    return if @user_initiated_disconnect

    log("[*] Reconnect attempt #{attempt}/#{MAX_RECONNECT_ATTEMPTS}...")
    begin
      open_rx_characteristic
      log("[+] Reconnected to: #{@device.name}")
      set_ui(true)
      start_auto_read
    rescue => e
      log("[-] Reconnect attempt #{attempt} failed: #{e.message}")
      if attempt < MAX_RECONNECT_ATTEMPTS
        schedule_reconnect(attempt + 1)
      else
        log('[-] Reached max reconnect attempts. Click Connect to retry.')
        @device = nil
        set_ui(false)
      end
    end
  end

  def disconnect
    @user_initiated_disconnect = true
    stop_auto_read

    return unless @device
    @rx_char.stop_notify if @rx_char
    @device.disconnect
    @device = nil
    @rx_char = nil
    log('[*] Disconnected')
    set_ui(false)
  end

  def set_ui(connected)
    if connected
      set_status('Connected')
      element('status').className = 'connected'
      element('btn-connect').setAttribute('disabled', 'true')
      element('btn-disconnect').removeAttribute('disabled')
    else
      set_status('Disconnected')
      element('status').className = 'disconnected'
      element('btn-connect').removeAttribute('disabled')
      element('btn-disconnect').setAttribute('disabled', 'true')
    end
  end

  def set_status(text)
    element('status').textContent = text
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

  # Notifications from rx_char fill @line_buffer directly via on_change.
  # Each tick we drain any complete lines and forward each sample.
  def poll_uart
    @line_buffer ||= ''
    while (idx = @line_buffer.index("\n"))
      line = @line_buffer.slice!(0..idx).strip
      JS.global.console.log("[DATA] #{line}")
      line.split(SAMPLE_SEPARATOR).each { |sample| send_data(sample) }
    end
  end

  def send_data(line)
    t = JS.global[:Date].now.to_i
    query = line.gsub(',', '&')
    url = "#{LOCAL_ENDPOINT}?#{query}&t=#{t}"

    JS.global.fetch(url) { |response| JS.global.console.log("[HTTP] GET #{response[:status]}") }
  end
end

Controller.new
