const int potPin = A0;
const int heartPin = A1;
const int buttonPin = 2;

void setup() {
  Serial.begin(115200); 
  pinMode(buttonPin, INPUT_PULLUP); 
}

void loop() {
  int potValue = analogRead(potPin);
  int heartValue = analogRead(heartPin);
  int buttonValue = (digitalRead(buttonPin) == LOW) ? 1 : 0;

  // Costruiamo il messaggio con un "Header" identificativo
  Serial.print("DATA,"); // Etichetta iniziale
  Serial.print(potValue);
  Serial.print(",");
  Serial.print(heartValue);
  Serial.print(",");
  Serial.println(buttonValue); // println invia il "\n" (a capo) finale

  delay(20); // ~50Hz
}