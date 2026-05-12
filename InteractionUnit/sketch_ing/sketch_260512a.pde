import processing.serial.*;
import oscP5.*;
import netP5.*;

Serial myPort;
OscP5 oscP5;
NetAddress superColliderDest;
NetAddress juceDest;

int potValue = 1;
int heartValue = 0;
int buttonValue = 0;

void setup() {
  size(200, 200);
  
  // 1. Setup Seriale
  printArray(Serial.list());
  // CAMBIA LO [0] con l'indice corretto della tua porta Arduino!
  String portName = Serial.list()[0]; 
  myPort = new Serial(this, portName, 115200);
  myPort.bufferUntil('\n'); // Leggi fino all'a capo
  
  // 2. Setup OSC
  oscP5 = new OscP5(this, 12000); // Processing ascolta sulla porta 12000 (non la usiamo, ma serve inizializzare)
  
  // Destinazioni OSC (IP Locale "127.0.0.1")
  superColliderDest = new NetAddress("127.0.0.1", 57120); // 57120 è la porta di default di SuperCollider
  juceDest = new NetAddress("127.0.0.1", 8000);          // Scegliamo la porta 8000 per la tua app JUCE
}

void draw() {
  background(50);
  stroke(255);
  strokeWeight(3);
  fill(255);

  float cx = width * 0.5;
  float cy = height * 0.5;
  float r = 55;

  // In base al valore del potenziometro disegna da 1 a 4 punti collegati
  if (potValue == 1) {
    point(cx, cy);
  } else if (potValue == 2) {
    float x1 = cx - r;
    float x2 = cx + r;
    line(x1, cy, x2, cy);
    point(x1, cy);
    point(x2, cy);
  } else if (potValue == 3) {
    float x1 = cx;
    float y1 = cy - r;
    float x2 = cx - r;
    float y2 = cy + r;
    float x3 = cx + r;
    float y3 = cy + r;
    line(x1, y1, x2, y2);
    line(x2, y2, x3, y3);
    line(x3, y3, x1, y1);
    point(x1, y1);
    point(x2, y2);
    point(x3, y3);
  } else {
    float x1 = cx - r;
    float y1 = cy - r;
    float x2 = cx + r;
    float y2 = cy - r;
    float x3 = cx + r;
    float y3 = cy + r;
    float x4 = cx - r;
    float y4 = cy + r;
    line(x1, y1, x2, y2);
    line(x2, y2, x3, y3);
    line(x3, y3, x4, y4);
    line(x4, y4, x1, y1);
    point(x1, y1);
    point(x2, y2);
    point(x3, y3);
    point(x4, y4);
  }

  fill(255);
  textAlign(CENTER, CENTER);
  text("Bridge Serial -> OSC\nIn esecuzione...\nPot: " + potValue + " Heart: " + heartValue + " Btn: " + buttonValue, width/2, 20);
}

void serialEvent(Serial myPort) {
  String val = myPort.readStringUntil('\n');
  if (val != null) {
    val = trim(val);
    
    // Controlliamo se il messaggio inizia con il nostro identificativo
    if (val.startsWith("DATA,")) {
      // Dividiamo la stringa usando la virgola
      String[] parts = split(val, ',');
      
      // Controlliamo di avere tutti i pezzi (L'etichetta + 3 valori = 4 pezzi)
      if (parts.length == 4) {
        int pot = int(parts[1]);
        int heart = int(parts[2]);
        int button = int(parts[3]);

        potValue = constrain(pot, 1, 4);
        heartValue = heart;
        buttonValue = button;
        
        // Creiamo il pacchetto OSC
        OscMessage myMessage = new OscMessage("/arduino/sensors");
        myMessage.add(pot);    // Parametro 0
        myMessage.add(heart);  // Parametro 1
        myMessage.add(button); // Parametro 2
        
        // Invia ai due software
        oscP5.send(myMessage, superColliderDest);
        oscP5.send(myMessage, juceDest);
      }
    }
  }
}
