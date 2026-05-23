---
name: send-app
description: Bundle examples/accelerometer.rb + road_to_rubykaigi classes and send to the Pico W as /home/app.mrb via `rake pico:send_app`. Use when the user wants to flash the latest accelerometer demo to the connected Pico.
user-invocable: true
allowed-tools:
  - Bash(bundle exec rake pico:send_app*)
  - Bash(rake pico:send_app*)
---

# /send-app — Flash the latest demo to Pico W

Runs `bundle exec rake pico:send_app` from the project root.

This task:

1. Concatenates `examples/road_to_rubykaigi/*.rb` into `tmp/road_to_rubykaigi.rb` (single `module RoadToRubykaigi` wrapper)
2. Bundles with `examples/accelerometer.rb` into `tmp/app_bundled.rb`
3. Sends to `/home/app.mrb` on the connected Pico W via `bin/send_file.rb --mrb` (auto-detects `/dev/cu.usbmodem*`)

## Prerequisites

- `PICORBC` env var set to the `picorbc` binary path (typically exported in shell rc; required by `bin/send_file.rb`)
- Pico W connected over USB with picoruby firmware running shell (not blocked in the BLE loop)

## Failure modes

- `no ACK` — Pico is busy emitting puts on USB CDC. Reboot the Pico and press `s` during the `Press 's' to skip running /etc/init.d/r2p2` window
- `No /dev/cu.usbmodem*` — no Pico connected, or different device path
- `picorbc: command not found` — `PICORBC` env not set

If the command fails, report the stderr to the user and suggest the matching remedy above. Do not retry automatically.
