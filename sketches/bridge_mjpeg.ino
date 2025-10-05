// bridge_mjpeg.ino
// UNO R4 WiFi: forward raw MJPEG (UART) -> USB CDC, no text output.
//
// Wiring (typical UART camera):
//   Camera TX  -> UNO D0 (RX1)
//   Camera RX  -> UNO D1 (TX1)   [optional, only if you need to send commands]
//   Camera GND -> UNO GND
//   Camera VCC -> 5V or 3V3 per your camera's spec
//
// Notes:
//   - CAM_BAUD must match the camera's UART baud.
//   - This sketch prints NOTHING to Serial. It only forwards bytes.
//   - If your camera requires commands, you can write them to Serial (USB)
//     and they’ll be forwarded to Serial1 (camera).

#ifndef LED_BUILTIN
#define LED_BUILTIN 13
#endif

static const unsigned long CAM_BAUD = 115200;

// Packets: larger buffer gives smoother USB writes.
static const size_t BUF_SIZE = 512;
uint8_t buf[BUF_SIZE];

void setup() {
  // USB CDC: the baud value is ignored on native USB, but set it anyway.
  Serial.begin(115200);

  // Camera UART on D0/D1.
  Serial1.begin(CAM_BAUD);

  // Optional: brief settle.
  delay(50);

  // Turn LED off initially.
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
}

void loop() {
  // Forward camera -> USB (core path)
  size_t n = Serial1.available();
  if (n) {
    if (n > BUF_SIZE) n = BUF_SIZE;
    n = Serial1.readBytes(buf, n);
    if (n) {
      Serial.write(buf, n);
      // Small visual heartbeat on traffic (very brief blink)
      digitalWrite(LED_BUILTIN, HIGH);
      // A tiny delay helps the USB buffer without adding latency.
      // (Comment out if you want maximum throughput.)
      delayMicroseconds(200);
      digitalWrite(LED_BUILTIN, LOW);
    }
  }

  // Optional: pass commands from USB -> camera (useful for VC0706/AT cmds)
  size_t m = Serial.available();
  if (m) {
    if (m > BUF_SIZE) m = BUF_SIZE;
    m = Serial.readBytes(buf, m);
    if (m) {
      Serial1.write(buf, m);
    }
  }
}

