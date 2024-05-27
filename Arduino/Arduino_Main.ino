//define digital pin used by leds and buttons

#define LED_PIN_P1 13      
#define LED_PIN_P2 12
#define LED_PIN_P3 11
#define LED_PIN_P4 10
#define LED_PIN_REC 9
#define LED_PIN_RESET 8
#define BUTTON_PIN_P1 7
#define BUTTON_PIN_P2 6
#define BUTTON_PIN_P3 5
#define BUTTON_PIN_P4 4
#define BUTTON_PIN_REC 3
#define BUTTON_PIN_RESET 2

//define LOW state for each pin and button

byte lastButtonStateP1 = LOW;
byte lastButtonStateP2 = LOW;
byte lastButtonStateP3 = LOW;
byte lastButtonStateP4 = LOW;
byte lastButtonStateREC = LOW;
byte lastButtonStateRESET = LOW;
byte ledStateP1 = LOW;
byte ledStateP2 = LOW;
byte ledStateP3 = LOW;
byte ledStateP4 = LOW;
byte ledStateREC = LOW;
byte ledStateRESET = LOW;

//define the amplitude array and some support variables

int AmplitudeArray[400];
int i = 0;
int j = 0;
unsigned long debounceDuration = 50; //[ms] 
unsigned long lastTimeButtonStateChanged = 0; //[ms]

void setup() {

  //initialize the serial protocol and define inputs and outputs

  Serial.begin(115200);
  pinMode(LED_PIN_P1, OUTPUT);
  pinMode(LED_PIN_P2, OUTPUT);
  pinMode(LED_PIN_P3, OUTPUT);
  pinMode(LED_PIN_P4, OUTPUT);
  pinMode(LED_PIN_REC, OUTPUT);
  pinMode(LED_PIN_RESET, OUTPUT);        
  pinMode(BUTTON_PIN_P1, INPUT);
  pinMode(BUTTON_PIN_P2, INPUT);
  pinMode(BUTTON_PIN_P3, INPUT);
  pinMode(BUTTON_PIN_P4, INPUT);
  pinMode(BUTTON_PIN_REC, INPUT);
  pinMode(BUTTON_PIN_RESET, INPUT);          

//fill the Amplitude array with -1

  for (int z = 0;z<400;z++) {
    AmplitudeArray[z] = -1;
  };
}
void loop() {

//define the values read from the analog pin

  int sensorValue1 = analogRead(A0);
  int sensorValue2 = analogRead(A1);
  int sensorValue3 = analogRead(A2);
  int sensorValue4 = analogRead(A3);
  int sensorValue5 = analogRead(A4);

  //normalize the values taken before from 0 to 127

  int val1 = (round(sensorValue1/8.055));
  int val2 = (round(sensorValue2/8.055));
  int val3 = (round(sensorValue3/8.055));
  int val4 = (round(sensorValue4/8.055));
  int val5 = round(abs((sensorValue5 - 320))*0.353);
//when a button is pressed, the led turn on; when is pressed again the led
//turn off. The reset led (white one) turn on when button is pressed and
//turn off when the button is released

  if (millis() - lastTimeButtonStateChanged > debounceDuration) {
    byte buttonStateP1    = digitalRead(BUTTON_PIN_P1);
    byte buttonStateP2    = digitalRead(BUTTON_PIN_P2);
    byte buttonStateP3    = digitalRead(BUTTON_PIN_P3);
    byte buttonStateP4    = digitalRead(BUTTON_PIN_P4);
    byte buttonStateREC   = digitalRead(BUTTON_PIN_REC);
    byte buttonStateRESET = digitalRead(BUTTON_PIN_RESET);



    if (buttonStateP1 != lastButtonStateP1) {
      lastTimeButtonStateChanged = millis();
      lastButtonStateP1 = buttonStateP1;
      if (buttonStateP1 == LOW) {
        ledStateP1 = (ledStateP1 == HIGH) ? LOW: HIGH;
        digitalWrite(LED_PIN_P1, ledStateP1);
      }
    }

    if (buttonStateP2 != lastButtonStateP2) {
      lastTimeButtonStateChanged = millis();
      lastButtonStateP2 = buttonStateP2;
      if (buttonStateP2 == LOW) {
        ledStateP2 = (ledStateP2 == HIGH) ? LOW: HIGH;
        digitalWrite(LED_PIN_P2, ledStateP2);
      }
    }

    if (buttonStateP3 != lastButtonStateP3) {
      lastTimeButtonStateChanged = millis();
      lastButtonStateP3 = buttonStateP3;
      if (buttonStateP3 == LOW) {
        ledStateP3 = (ledStateP3 == HIGH) ? LOW: HIGH;
        digitalWrite(LED_PIN_P3, ledStateP3);
      }
    }

    if (buttonStateP4 != lastButtonStateP4) {
      lastTimeButtonStateChanged = millis();
      lastButtonStateP4 = buttonStateP4;
      if (buttonStateP4 == LOW) {
        ledStateP4 = (ledStateP4 == HIGH) ? LOW: HIGH;
        digitalWrite(LED_PIN_P4, ledStateP4);
      }
    }    

    if (buttonStateREC != lastButtonStateREC) {
      lastTimeButtonStateChanged = millis();
      lastButtonStateREC = buttonStateREC; 
      if (buttonStateREC == LOW) {
        ledStateREC = (ledStateREC == HIGH) ? LOW: HIGH;
        digitalWrite(LED_PIN_REC, ledStateREC);
        if (ledStateREC == HIGH) {
          for (int z = 0;z<400;z++) {
            AmplitudeArray[z] = -1;
            i = 0;
          };
        } 
      }
    }

    if(buttonStateRESET == HIGH){
      for (int z = 0;z<400;z++) {
        AmplitudeArray[z] = -1;
        digitalWrite(LED_PIN_RESET, HIGH);
      }
    }
    else{
      digitalWrite(LED_PIN_RESET, LOW);      
    }
  }

//When a potentiometer led is on, it sends a control serial message with 1 and another message
//with the value of the assigned potentiometer. When the led is off, it sends
//a control value of 0 and a fixed value of 127

  if (ledStateP1 == HIGH){
    Serial.print(1);
    Serial.print('a');
    Serial.print(val1);
    Serial.print('b');
            
  }
  else{
    Serial.print(0);
    Serial.print('a');
    Serial.print(127);
    Serial.print('b');
  };

  if (ledStateP2 == HIGH){
    Serial.print(1);
    Serial.print('c');
    Serial.print(val2);
    Serial.print('d');
            
  }
  else{
    Serial.print(0);
    Serial.print('c');
    Serial.print(127);
    Serial.print('d');
  };  

  if (ledStateP3 == HIGH){
    Serial.print(1);
    Serial.print('e');
    Serial.print(val3);
    Serial.print('f');
            
  }
  else{
    Serial.print(0);
    Serial.print('e');
    Serial.print(127);
    Serial.print('f');
  };

  if (ledStateP4 == HIGH){
    Serial.print(1);
    Serial.print('g');
    Serial.print(val4);
    Serial.print('h');
            
  }
  else{
    Serial.print(0);
    Serial.print('g');
    Serial.print(127);
    Serial.print('h');
  };

//When the REC led is on the amplitude array is filled with the values
//read by the mic sensor (the rec limit is 20 seconds, after which the array 
//values will be overwritten). It will send the read value and control
//value for loop and recording

  if (ledStateREC == HIGH){
    AmplitudeArray[i] = val5;
    Serial.print(1);
    Serial.print('i'); // record button state
    Serial.print(0); 
    Serial.print('j'); // loop state
    Serial.print(AmplitudeArray[i]); // mic value
    Serial.print('k'); // mic value
    i = i + 1;                       
    if (i == 400) { // 20 seconds recording
      i = 0;
    }
  }
  else{ //when the first element of the array is -1 and the led is off,
        //no actions are taken and the value sent is fixed to 128   
    if (AmplitudeArray[0] == -1){
      Serial.print(0);
      Serial.print('i');
      Serial.print(0);
      Serial.print('j');
      Serial.print(127);
      Serial.print('k');
    }
    else{ //when the first element of the array is not -1
          //and the led is off, we are in the loop phase
          //where every element of the array is repeated until
          //the end of the array or a -1 value, where the array begin from
          //the start
      if (AmplitudeArray[j] != -1) {
        Serial.print(0);
        Serial.print('i');  
        Serial.print(1);
        Serial.print('j');
        Serial.print(AmplitudeArray[j]);
        Serial.print('k'); 
        j = j + 1;   
      }
      else {
        j = 0;
        Serial.print(0);
        Serial.print('i'); 
        Serial.print(1);
        Serial.print('j');  
        Serial.print(AmplitudeArray[j]); 
        Serial.print('k');    
       }
    }
  }
  delay(50);
}
