import processing.serial.*;
import oscP5.*;
import netP5.*;

Serial myPort;
OscP5 oscP5;
NetAddress superColliderDest;
NetAddress juceDest;

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
  fill(255);
  textAlign(CENTER, CENTER);
  text("Bridge Serial -> OSC\nIn esecuzione...", width/2, height/2);
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
