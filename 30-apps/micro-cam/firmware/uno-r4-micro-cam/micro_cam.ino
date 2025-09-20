#include <SPI.h>
#include <WiFiS3.h>
#include <ArduCAM.h>
#include "memorysaver.h"

#define CAM_CS 7
#define PIR_PIN 2
const char* WIFI_SSID = "YOUR_SSID";
const char* WIFI_PASS = "YOUR_PASS";
const char* UPLOAD_HOST = "camera-uploader.suite.home.arpa";
const uint16_t UPLOAD_PORT = 80;
const char* UPLOAD_PATH = "/upload";

ArduCAM myCAM(OV2640, CAM_CS);
volatile bool motionFlag = false;

void onMotion() { motionFlag = true; }

void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  unsigned long t0 = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - t0 < 15000) delay(200);
}

bool httpPostJPEG(uint8_t *buf, size_t len) {
  WiFiClient client;
  if (!client.connect(UPLOAD_HOST, UPLOAD_PORT)) return false;

  String boundary = "----arduinoBoundary7e3f";
  String hdr = "";
  hdr += "POST " + String(UPLOAD_PATH) + " HTTP/1.1\r\n";
  hdr += "Host: " + String(UPLOAD_HOST) + "\r\n";
  hdr += "Content-Type: multipart/form-data; boundary=" + boundary + "\r\n";
  hdr += "Connection: close\r\n";

  String meta =
    "--" + boundary + "\r\n"
    "Content-Disposition: form-data; name=\"meta\"\r\n\r\n"
    "{\"source\":\"uno-r4\",\"counter\":\"1\"}\r\n"
    "--" + boundary + "\r\n"
    "Content-Disposition: form-data; name=\"file\"; filename=\"frame.jpg\"\r\n"
    "Content-Type: image/jpeg\r\n\r\n";

  String end = "\r\n--" + boundary + "--\r\n";
  size_t contentLen = meta.length() + len + end.length();
  hdr += "Content-Length: " + String(contentLen) + "\r\n\r\n";

  client.print(hdr);
  client.print(meta);
  client.write(buf, len);
  client.print(end);

  unsigned long t0 = millis();
  while (client.connected() && millis() - t0 < 5000) {
    if (client.available()) {
      String line = client.readStringUntil('\n');
      if (line.startsWith("HTTP/1.1 200")) return true;
    }
  }
  return false;
}

bool captureAndSend() {
  pinMode(CAM_CS, OUTPUT);
  SPI.begin();
  myCAM.write_reg(0x07, 0x80); delay(100);
  myCAM.write_reg(0x07, 0x00); delay(100);

  uint8_t vid, pid;
  myCAM.rdSensorReg8_8(0x0A, &vid);
  myCAM.rdSensorReg8_8(0x0B, &pid);
  if (vid == 0x00 || pid == 0x00) return false;

  myCAM.set_format(JPEG);
  myCAM.InitCAM();
  myCAM.OV2640_set_JPEG_size(OV2640_800x600);
  delay(200);

  myCAM.flush_fifo();
  myCAM.clear_fifo_flag();
  myCAM.start_capture();

  unsigned long t0 = millis();
  while (!myCAM.get_bit(ARDUCHIP_TRIG, CAP_DONE_MASK)) {
    if (millis() - t0 > 3000) return false;
  }

  uint32_t len = myCAM.read_fifo_length();
  if (len < 100 || len > 250000) return false;

  uint8_t *jpg = (uint8_t*)malloc(len);
  if (!jpg) return false;

  myCAM.CS_LOW();
  myCAM.set_fifo_burst();
  for (uint32_t i = 0; i < len; i++) {
    jpg[i] = SPI.transfer(0x00);
  }
  myCAM.CS_HIGH();

  connectWiFi();
  bool ok = (WiFi.status() == WL_CONNECTED) && httpPostJPEG(jpg, len);
  free(jpg);
  return ok;
}

void setup() {
  pinMode(PIR_PIN, INPUT);
  attachInterrupt(digitalPinToInterrupt(PIR_PIN), onMotion, RISING);
}

void loop() {
  if (motionFlag) {
    motionFlag = false;
    captureAndSend();
  }
  delay(50);
}
