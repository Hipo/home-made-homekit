#include <SPI.h>
#include <Ethernet.h>

#include <avr/wdt.h>

#include <PusherClient.h>

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

PusherClient client;

#define FLOOR1  2
#define FLOOR2  3
#define FLOOR3  5
#define FLOOR4  6


void setup() {
  pinMode(FLOOR1, OUTPUT);
  pinMode(FLOOR2, OUTPUT);
  pinMode(FLOOR3, OUTPUT);
  pinMode(FLOOR4, OUTPUT);

  Serial.begin(9600);

  turnOnFloor1("");
  turnOnFloor2("");
  turnOnFloor3("");
  turnOnFloor4("");

  wdt_enable(WDTO_8S);

  Serial.println("Init...");

  if (Ethernet.begin(mac) == 0) {
    Serial.println("Init Ethernet failed");
    while(1) {}
  }
  
  wdt_reset();
  
  Serial.println("Connecting...");
  
  if (client.connect("138289ba194ec1862b00")) {
    wdt_reset();
  
    Serial.println("Connected");

    client.bind("floor1_on", turnOnFloor1);
    client.bind("floor1_off", turnOffFloor1);

    client.bind("floor2_on", turnOnFloor2);
    client.bind("floor2_off", turnOffFloor2);

    client.bind("floor3_on", turnOnFloor3);
    client.bind("floor3_off", turnOffFloor3);

    client.bind("floor4_on", turnOnFloor4);
    client.bind("floor4_off", turnOffFloor4);

    client.bind("all_off", turnOffAll);
    client.bind("all_on", turnOnAll);

    client.subscribe("homekit_channel");
  }

  wdt_disable();
}

void loop() {
  if (client.connected()) {
    client.monitor();
  } else {
    wdt_enable(WDTO_8S);
  
    Serial.println("Connection lost, reconnecting...");

    while(1) {};
  }
}

void turnOffFloor1(String data) {
  Serial.println("FLOOR 1 OFF");
  digitalWrite(FLOOR1, HIGH);
}

void turnOnFloor1(String data) {
  Serial.println("FLOOR 1 ON");
  digitalWrite(FLOOR1, LOW);
}

void turnOffFloor2(String data) {
  digitalWrite(FLOOR2, HIGH);
}

void turnOnFloor2(String data) {
  digitalWrite(FLOOR2, LOW);
}

void turnOffFloor3(String data) {
  digitalWrite(FLOOR3, HIGH);
}

void turnOnFloor3(String data) {
  digitalWrite(FLOOR3, LOW);
}

void turnOffFloor4(String data) {
  digitalWrite(FLOOR4, HIGH);
}

void turnOnFloor4(String data) {
  digitalWrite(FLOOR4, LOW);
}

void turnOffAll(String data) {
  turnOffFloor1("");
  turnOffFloor2("");
  turnOffFloor3("");
  turnOffFloor4("");
}

void turnOnAll(String data) {
  turnOnFloor1("");
  turnOnFloor2("");
  turnOnFloor3("");
  turnOnFloor4("");
}

