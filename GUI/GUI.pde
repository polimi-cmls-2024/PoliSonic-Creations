// =============================================== GUI PROJECT ======================================================//

// In this Processing file we will implement the GUI for the Synthesizer application. 
// It will feature one oscillator, 4 different effects and the possibility to modulate the Envelope
//   of either the filter cutoff or the amplitude through an air pressure sensor connected via Arduino 
//  (see "Arduino_Main.ino" for more info about this topic)


// ------------------------------------------------ Declarations -----------------------------------------------------//

// 1)  IMPORT LIBRARY 
//     In this section we are going to import all the libraries needed to implement the knob control, osc and arduino 
//     communication.

import oscP5.*;
import netP5.*;
import controlP5.*;
import processing.serial.*;

// 2) OBJECTS DECLARATION

//    These are the objects that we'll need to implement the interaction part. 

OscP5 oscP5;
NetAddress myRemoteLocation;
ControlP5 cp5;
Serial myPort;

//    These are the objects that we'll need to implement the GUI/control part
//    We'll need (in order): 
//          - 4 + 1 buttons for the activation of the 4 effects and the recording
//          - 2 knobs to implement basic controls such as master volume, detuning and panning 
//          - 6 knobs to control the filter
//          - 4 knobs to control the amp envelope
//          - 4 knobs + 2 to control the effects parameters.

Button filterButton, detuneButton, chorusButton, distortButton, recordButton; 
Knob detuneKnob, volumeKnob, panKnob; //Basic control knobs
Knob cutOffKnob, resonanceKnob, filterAttackKnob, filterDecayKnob, filterSustainKnob, filterReleaseKnob; //Filter Knobs
Knob attackKnob, decayKnob, sustainKnob, releaseKnob; //ADSR knobs
Knob chorusMixKnob, chorusDepthKnob, chorusDelayKnob, chorusFeedbackKnob; // Chorus knobs
Knob distortionMixKnob, distortionFilterKnob; // Distortion knobs

//    Two dropdown lists will be used for the waveform selection and the microphone modulation selection

DropdownList d1, d2;

// 3) GLOBAL VARIABLES DECLARATION

String charArray = ""; // to read Arduino serial code
boolean chorusButtonState = false; // Chorus button state: false=off, true=on
boolean distortionButtonState = false; // Distortion button state: false=off, true=on
boolean cutoffButtonState = false; // Filter button state: false=off, true=on
boolean detuneButtonState = false; // Detune button state: false=off, true=on
boolean recordButtonState = false; // Record button state: false=off, true=on
boolean loopButtonState = false; // Loop button state: false=off, true=on
int cutOff = 200; // Initial cutoff value
float detune = 0; // Valore iniziale del knob Detune
float panKnobValue = 0; // Valore iniziale del knob Pan
int attack = 0, decay = 0, sustain = 0, release = 0; // Variables for the amp envelope
float amp = 1.0, pan = 0.0, waveform, voiceSelect, volume = 1.0; // Variables for basic controls
float chorusMix = 1, chorusDepth = 0, chorusDelay = 0, chorusFeedback = 0; // Chorus global variables
float distortionMix = 1, distortionFilter = 0; // Distortion global variables
float resonance = 0; // For the filter resonance (float)
int filterAttack = 0, filterDecay = 0, filterSustain = 0, filterRelease = 0; // For the filter envelope
PImage img, img2, img3, img4, img5, img6, img7, img8, img9, img10, img11, img12, img13, img14, img15, img16; // Images for GUI changes
PFont myFont; // To import a different font (used to highlight the filter envelope section).


// ---------------------------------------------------------- Setup --------------------------------------------------------------//

// This function will contain the vast majority of our code: here we'll set up all the GUI knobs and parameters
void setup() {

  size(700, 500); // Size of the window
  myFont = createFont("YuppyTC-Regular", 12); //Font creation
// Import images 
  img = loadImage("3biscot.png");
  img2 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/3biscot(evil).png");
  img3 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/6biscot.png");
  img4 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/6biscot(evil).png");
  img5 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/3bisblurred.png");
  img6 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/3bisblurred(evil).png");
  img7 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/3biscuba.png");
  img8 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/3biscuba(evil).png");
  img9 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/3biscublurred.png");
  img10 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/3biscublurred(evil).png");
  img11 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/6bisblurred.png");
  img12 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/6bisblurred(evil).png");
  img13 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/6biscuba.png");
  img14 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/6biscuba(evil).png");
  img15 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/6biscublurred.png");
  img16 = loadImage("/Users/costa/Desktop/CMLS Final/GUI/6biscublurred(evil).png");

// Set an image as background
  background(img);

// OSC communication setup: here we choose where we want to send the message in terms of address and port. 

  oscP5 = new OscP5(this, 12000); // Initialize oscP5 on port 12000
  myRemoteLocation = new NetAddress("127.0.0.1", 57120); // Address and port of the OSC receiver
  
// Arduino setup

  String portName = Serial.list()[2]; // Sostituisci con il numero di porta corretto
  myPort = new Serial(this, portName, 115200);

// Controllers setup
  
  cp5 = new ControlP5(this);  // Inizializzazione del ControlP5

//=======================  BUTTONS ===========================//

// Here we choose what look should the 5 buttons right after the setup

  // Cutoff 
 filterButton = cp5.addButton("cutoffState")     // Instantiation of "filterButton", which will be addressed to as "cutoffState"
     .setLabel("Filter")                         // Visualized name of the button
     .setPosition(170, 175)                      // Choose the position in the GUI window
     .setSize(20, 20)                            // Set the button size
     .setColorBackground(color(20, 49, 9))       // Set the color of the button's background
     .setColorForeground(color(111,138,183));    // Set the color of the button when we land on it with the mouse

  // Detune
 detuneButton = cp5.addButton("detuneState")
     .setLabel("Detune")
     .setPosition(290, 175)
     .setSize(20, 20)
     .setColorBackground(color(20, 49, 9))
     .setColorForeground(color(111,138,183));

  // Chorus
  chorusButton = cp5.addButton("chorusState")
     .setLabel("Chorus")
     .setPosition(410, 175)
     .setSize(20, 20)
     .setColorBackground(color(20, 49, 9))
     .setColorForeground(color(111,138,183));

  // Distortion  
  distortButton = cp5.addButton("distortionState")
   .setLabel("Distortion")
   .setPosition(530, 175) 
   .setSize(20, 20)
   .setColorBackground(color(20, 49, 9))
   .setColorForeground(color(111,138,183));

   
  // Record  
  recordButton = cp5.addButton("recordButtonState")
   .setLabel("Record")
   .setPosition(75, 400) // Adjust the position as needed
   .setSize(100, 50)
   .setColorBackground(color(76,1,20))
   .setColorForeground(color(111,138,183));
   
   
// ======================= Effect Knobs ============================//

// Same as before, but with the knobs

  // Chorus Mix Knob
  chorusMixKnob = cp5.addKnob("chorusMix")           // Instantiate the knob, which will be identified as "chorusMix"
     .setLabel("Mix")                                // Name visualized on the screen
     .setRange(0.0, 1)                               // Knob Range
     .setValue(1)                                    // Initial Value
     .setPosition(400, 225)                          // Position on the GUI
     .setRadius(20)                                  // Dimensions
     .setDragDirection(1)                            // Vertical drag direction for a more intuitive user experience
     .setColorBackground(color(105, 89, 88))         // Background color
     .setColorForeground(color(219,216,174))         // Color of the knob's parameter
     .setColorActive(color(234,244,211));            // Set the color of the button when we land on it with the mouse
     
     
  // Add the Chorus Depth
  chorusDepthKnob = cp5.addKnob("chorusDepth")
     .setLabel("Depth")
     .setRange(0.0, 1)
     .setValue(0)
     .setPosition(365, 280)
     .setRadius(20)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));

  // Add the Chorus Rate
  chorusDelayKnob = cp5.addKnob("chorusDelay")
     .setLabel("Delay")
     .setRange(0.0, 1)
     .setValue(0)
     .setPosition(435, 280) 
     .setRadius(20)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));
     
  // Add the Chorus Feedback
  chorusFeedbackKnob = cp5.addKnob("chorusFeedback")
     .setLabel("FeedBack")
     .setRange(0, 1)
     .setValue(0.5)
     .setPosition(400, 330)
     .setRadius(20)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));    
     
  // Add the Distortion Mix
  distortionMixKnob = cp5.addKnob("distortionMix")
     .setLabel("Mix")
     .setRange(0.0, 1)
     .setValue(1)
     .setPosition(520, 225)
     .setRadius(20)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));
     
  // Add the Distortion Filter
  distortionFilterKnob = cp5.addKnob("distortionFilter")
     .setLabel("Filter")
     .setRange(0.0, 1)
     .setValue(1)
     .setPosition(520, 280) 
     .setRadius(20)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));  
     
// ======================= ADSR Envelope Knobs ============================//  

  // Add the Attack Knob  
  attackKnob = cp5.addKnob("attack")
     .setLabel("Attack")
     .setRange(1, 100)
     .setValue(0.01)
     .setPosition(65, 70)
     .setRadius(15)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));

  // Add the Decay knob
  decayKnob = cp5.addKnob("decay")
     .setLabel("Decay")
     .setRange(0, 100)
     .setValue(0)
     .setPosition(110, 70) 
     .setRadius(15)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));

  // Add the Sustain knob
  sustainKnob = cp5.addKnob("sustain")
     .setLabel("Sustain")
     .setRange(0, 100)
     .setValue(100)
     .setPosition(155, 70)
     .setRadius(15)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));
     
  // Add the Release knob
  releaseKnob = cp5.addKnob("release")
     .setLabel("Release")
     .setRange(0, 100)
     .setValue(0)
     .setPosition(200, 70) 
     .setRadius(15)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));

// ======================= Filter Knobs ============================// 
     
  cutOffKnob = cp5.addKnob("cutOff")
     .setLabel("CutOff")
     .setRange(0, 200)
     .setValue(200)
     .setPosition(160, 225)
     .setRadius(20)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));

  // Add the Resonance knob
  resonanceKnob = cp5.addKnob("resonance")
    .setLabel("Resonance")
     .setRange(0, 1)
     .setValue(1)
     .setPosition(160, 280)
     .setRadius(20)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));
     
  // Add the Filter Attack Knob  
  filterAttackKnob = cp5.addKnob("filterAttack")
     .setLabel("Attack")
     .setRange(1, 100)
     .setValue(1)
     .setPosition(90, 225)
     .setRadius(15)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));

  // Add the Filter Decay knob
  filterDecayKnob = cp5.addKnob("filterDecay")
     .setLabel("Decay")
     .setRange(0, 100)
     .setValue(0)
     .setPosition(90, 275) 
     .setRadius(15)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));

  // Add the Filter Sustain knob
  filterSustainKnob = cp5.addKnob("filterSustain")
     .setLabel("Sustain")
     .setRange(0, 100)
     .setValue(100)
     .setPosition(90, 325)
     .setRadius(15)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));
         
     
// ======================= Basic Control Knobs ============================//   
     
  // Add the Volume knob
  volumeKnob = cp5.addKnob("volume")
     .setLabel("Volume")
     .setRange(0, 1)
     .setValue(1)
     .setPosition(520, 30) 
     .setRadius(20)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));
  
  // Add the Detune knob
  detuneKnob = cp5.addKnob("detune")
    .setLabel("Amount")
     .setRange(0, 0.1)
     .setValue(0)
     .setPosition(280, 225)
     .setRadius(20)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));
     
  // Add the Pan knob
  panKnob = cp5.addKnob("pan")
     .setLabel("Pan")
     .setRange(-1, 1)
     .setValue(0)
     .setPosition(600, 30)
     .setRadius(20)
     .setDragDirection(1)
     .setColorBackground(color(105, 89, 88))
     .setColorForeground(color(219,216,174))
     .setColorActive(color(234,244,211));

     
     
// ======================= DROPDOWN  MENU ======================== //

  // Dropdown menu for the oscillator's waveform
  d1 = cp5.addDropdownList("waveform")
                       .setPosition(50, 40)
                       .setSize(200, 120)
                       .setColorBackground(color(91,60,45))
                       .setColorForeground(color(219,216,174))
                       .setColorActive(color(234,244,211))                    
                       .setItemHeight(20)
                       .setBarHeight(15);

  d1.addItem("Sin", 1);                                        // Add three items corresponding to the various waveform that the user can choose 
  d1.addItem("Square", 2);
  d1.addItem("Saw", 3);
  d1.getCaptionLabel().set("Select waveform");                 // Add a "waveform select" option for the setup 
  
  // Dropdown menu for the parameter assignment
  d2 = cp5.addDropdownList("voiceSelect")
                       .setPosition(200, 400)
                       .setSize(100, 120)
                       .setColorBackground(color(91,60,45))
                       .setColorForeground(color(219,216,174))
                       .setColorActive(color(234,244,211))
                       .setItemHeight(20)
                       .setBarHeight(15);

  d2.addItem("Cutoff", 1);                                     // Add two items corresponding to the modulation options for the incoming microphone signal  
  d2.addItem("Amp", 2);
  d2.getCaptionLabel().set("Select Control");
  
  
}


// ---------------------------------------------------------- Draw --------------------------------------------------------------//

// Here we'll describe the behaviour of the GUI in response to some specific actions and interactions with the user and peripherics

void draw() {

  background(img);
  fill(234,244,211);              // Choose color of the texts (for the Filter Envelope section)
  textAlign(CENTER, CENTER);      // Choose the position of the text for controllers
  textFont(myFont);               // Choose the font of the filter envelope label
  text(" FILTER\n ENVELOPE", 105, 190); // Filter envelope label

  // Now we define how the GUI background should adjourn depending on which button is on 

  if (distortionButtonState){ 
  background(img2);
    }
    else if(chorusButtonState){
  background(img3);
    }
  
  if (chorusButtonState && distortionButtonState) {
  background(img4);  
    }

  if (detuneButtonState) {
  background(img5);  
  }
  
  if (distortionButtonState && detuneButtonState) {
  background(img6);  
    }
    
  if (cutoffButtonState) {
  background(img7);  
    }
    
  if (cutoffButtonState && distortionButtonState) {
  background(img8);  
    }
    
  if (cutoffButtonState && detuneButtonState) {
  background(img9);  
    }
    
  if (cutoffButtonState && detuneButtonState && distortionButtonState) {
  background(img10);  
    } 
    
  if (chorusButtonState && detuneButtonState) {
  background(img11);  
    }
    
  if (chorusButtonState && detuneButtonState && distortionButtonState) {
  background(img12);  
    }
    
  if (chorusButtonState && cutoffButtonState) {
  background(img13);  
    }
    
  if (chorusButtonState && cutoffButtonState && distortionButtonState) {
  background(img14);  
    }
   
  if (chorusButtonState && cutoffButtonState && detuneButtonState) {
  background(img15);  
    }
      
  if (chorusButtonState && cutoffButtonState && detuneButtonState && distortionButtonState) {
  background(img16);  
    }

// ============================ ARDUINO INTERACTION ================================= //

// This code is used to interact with an Arduino device. It reads data sent from the Arduino over a serial port and uses it to control various parameters of a sound synthesis system. 
// Here’s a breakdown of what each part does:
// 1. myPort.available() > 0: This checks if there is any data available to read from the serial port.
// 2. myPort.readChar(): This reads a single character from the serial port.
// 3. Character.isDigit(receivedChar): This checks if the received character is a digit. If it is, it appends the digit to a string (charArray).
// 4. The following if statements check if the received character matches a specific letter. Each letter corresponds to a different parameter of the sound synthesis system. 
// If a match is found, the code parses the string of digits into an integer or a boolean value and uses it to update the corresponding parameter. The string of digits is then cleared.

   while (myPort.available() > 0) {
      boolean bool = false;
      char receivedChar = myPort.readChar();
      if (Character.isDigit(receivedChar)) {
        charArray += receivedChar; 
      } else if (receivedChar == 'b') {
        float val = Integer.parseInt(charArray);
        cutOff = round(map(val, 0, 127, 0, 200));
        charArray = ""; 
      } else if (receivedChar == 'a') {
        bool = (Integer.parseInt(charArray) == 1);
        if(bool != cutoffButtonState){
          cutoffButtonState = !cutoffButtonState;
        }
        charArray = ""; // Clear the string        
      }
      else if (receivedChar == 'c') {
        bool = (Integer.parseInt(charArray) == 1);
        if(bool != detuneButtonState){
          detuneButtonState = !detuneButtonState;
        }
        charArray = ""; // Clear the string        
        }
        else if (receivedChar == 'd') {
        detune = map(Integer.parseInt(charArray), 0, 127, 0, 0.1);
        charArray = ""; 
        }
        else if (receivedChar == 'e') {
        bool = (Integer.parseInt(charArray) == 1);
        println(bool);
        if(bool != chorusButtonState){
          chorusButtonState = !chorusButtonState;
        }
        charArray = ""; // Clear the string        
        }
        else if (receivedChar == 'f') {
        chorusMix = map(Integer.parseInt(charArray), 0, 127, 0, 1);
        charArray = ""; 
        }
        else if (receivedChar == 'g') {
        bool = (Integer.parseInt(charArray) == 1);
        println(bool);
        if(bool != distortionButtonState){
          distortionButtonState = !distortionButtonState;
        }
        charArray = ""; // Clear the string        
        }
        else if (receivedChar == 'h') {
        distortionMix = map(Integer.parseInt(charArray), 0, 127, 0, 1);
        charArray = ""; 
        }
        else if (receivedChar == 'i') {
          bool = (Integer.parseInt(charArray) == 1);
          if(bool != recordButtonState){
            recordButtonState = !recordButtonState;
          }     
          charArray = "";
        }
        else if (receivedChar == 'j') {
          bool = (Integer.parseInt(charArray) == 1);
          if(bool != loopButtonState){
            loopButtonState = !loopButtonState;
          }     
          charArray = "";
        }
        else if (receivedChar == 'k') {
          amp = Integer.parseInt(charArray);
          //amp = logScale((int)Integer.parseInt(charArray), 127, 0.0, 127.0);
          //println(amp);       
          charArray = ""; 
        }          
  }

// ========================= CONTROLLERS UPDATE ========================== //
  
// Record Button Update

  if(recordButtonState){                                       // "recordButtonState" is our variable that tells us if the record button is in "record" mode: true if active
     recordButton.setValue(1);                                 // When we enter this "if" the "recordButtonState" is set as 
                                                               //   "true", so we need to adjourn the corresponding controller's value, which we're going to send to SuperCollider 
     recordButtonState = !recordButtonState;                   // After the recording is ended, we need to go to the next state 
                                                               //    of the recordButton, so we adjourn this value in order to avoid entering again this "if" section.
     recordButton.setLabel("Record");                          
     recordButton.setColorBackground(color(194, 1, 20));
     if (d2.getValue() == 1){                            // We're still in the recordButtonState "if". This second conditional is true when the second dropdown list is on 
                                                         //   "amp" mode: this means that we're going to modulate the amplitude through the sensor's input
     amp = map(amp, 0, 127, 0.3, 0.8);                   // Here we map the sensor's amplitude that we receive from arduino inside the range "0.3-0.8", which has been optimized through testing
     sendOscMessage("/amp", amp);                        // Now we can send the OSC message through the "sendOscMessage" function, that is used
                                                         //    for the interaction logic taking into account arduino messages
       } 
       else if (d2.getValue() == 0){                     // Same as above, but in this case we select the filter cutoff modulation, which is mapped in the range 70-200
        amp = map(amp, 0, 127, 70, 200);
        cutOffKnob.setValue(amp);
        sendOscMessage("/cutOff", amp);
       } 
       else {                                            // If the mode selection has yet to be done, don't do anything.
       }
     }  
   else if(loopButtonState){                                    // If the "record" button isn't in the record mode, then "recordButtonState" == "false"
                                                                //    and we enter in the "loop" state, through another state variable
     recordButton.setLabel("Loop");                             // Note: we don't need to adjourn the recordButton state because it's active in this case too: here we're still
                                                                //    sending osc messages, but they're looped.
     loopButtonState = !loopButtonState;                        // Again, this is needed to go to the next state
     recordButton.setColorBackground(color(150, 1, 200));
     if (d2.getValue() == 1){                            // Same as above
       amp = map(amp, 0, 127, 0.3, 0.8);
       sendOscMessage("/amp", amp);
       } 
     else if (d2.getValue() == 0){                       // Same as above
        amp = map(amp, 0, 127, 70, 200);
        cutOffKnob.setValue(amp);
        sendOscMessage("/cutOff", amp);
       } 
       else {
       
       }
   }
   else if(!loopButtonState && !recordButtonState){             // If we're not in any of those two cases, then turn off the button. This is accessed with the arduino reset button
     recordButton.setValue(0);
     recordButton.setLabel("Record");
     loopButtonState = !loopButtonState;
     recordButton.setColorBackground(color(76,1,20));
   };

  // Filter update                                              // If the filter cutoff button is on (so if the filter's state variable is true), we enter this loop
  if(cutoffButtonState){  
     filterButton.setValue(1);                              
     cutoffButtonState = !cutoffButtonState;                  
     filterButton.setColorBackground(color(40, 150, 90));
     sendOscMessage("/cutoffState", 1);                         // We're telling SC that the filter is active. We will modify the "lpfOn" parameter in SC
     if(d2.getValue() != 0){                                    // If the second dropdown list isn't set on "Filter Cutoff", then we receive values from the knob
       cutOffKnob.setValue(cutOff);                             // We set the cutoff via GUI, so the controller can be manipulated through the GUI when it isn't chosen in the dropdown list
       sendOscMessage("/cutOff", cutOff);                       // Send the cutoff value to SC
     }
     }
  
   else{
     filterButton.setValue(0);                                  // In this case, the button is off and we don't send the cutoff data to SC, but just the "cutoffState" variable
     cutoffButtonState = !cutoffButtonState;
     filterButton.setColorBackground(color(20, 49, 9));
     sendOscMessage("/cutoffState", 0);
   };
   
   // Detune update
   if(detuneButtonState){                            // Same as above
     detuneButton.setValue(1);
     detuneButtonState = !detuneButtonState;
     detuneButton.setColorBackground(color(40, 150, 90));
     sendOscMessage("/detuneState", 1);
     detuneKnob.setValue(detune);
     sendOscMessage("/detune", detune);
     }
                                                                // Since this parameter cannot be modulated through the sensor's output, we don't need to worry about the dropdown list's selection
   else{
     detuneButton.setValue(0);                       // Same as above, when the button is off we only send the "detuneState" variable
     detuneButtonState = !detuneButtonState;
     detuneButton.setColorBackground(color(20, 49, 9));
     sendOscMessage("/detuneState", 0);
   };
   
   // Chorus update
   if(!chorusButtonState){                          // Same as above
     chorusButton.setValue(1);
     chorusButtonState = !chorusButtonState;
     chorusButton.setColorBackground(color(20, 49, 9));
     sendOscMessage("/chorusState", 1);
     }
  
   else{                                            // What happens when the chorus is on
     chorusButton.setValue(0);
     chorusButtonState = !chorusButtonState;
     chorusButton.setColorBackground(color(40, 150, 90));
     sendOscMessage("/chorusState", 0);
     chorusMixKnob.setValue(chorusMix);
     sendOscMessage("/chorusMix", chorusMix);
   };
   
   // Distortion update      
   if(!distortionButtonState){                         // Same as above
     distortButton.setValue(1);
     distortionButtonState = !distortionButtonState;
     distortButton.setColorBackground(color(20, 49, 9));
     sendOscMessage("/distortionState", 1);
     }
  
   else{
     distortButton.setValue(0);                    // What happens when the distortion is on
     distortionButtonState = !distortionButtonState;
     distortButton.setColorBackground(color(40, 150, 90));
     distortionMixKnob.setValue(distortionMix);
     sendOscMessage("/distortionMix", distortionMix);
     sendOscMessage("/distortionState", 0);
   };
delay(70);                                        // Reduce CPU usage to avoid sound distortion and crackling
}

// ---------------------------------------------------------- Functions --------------------------------------------------------------//

void controlEvent (ControlEvent theEvent){
  String which_control = theEvent.getName().toString(); // A Control Event has arrived: Which Controller generated it? 
  String address = null; 
  float value = 0.0;
  switch (which_control) {        // Now that we know which controller generated it, we can proceed to distinguish every case. 
          // We use a switch to effectively select every single case
// ------------------- Pulsanti ------------------//
    case "cutoffState": 
       address = which_control;                         // The address corresponds to the name of the controller 
       cutoffButtonState = !cutoffButtonState;          // Adjourn the state variable
       value = cutoffButtonState ? 1 : 0;               // If the cutoffButtonState is equal to 1, then "value" takes 1 when "cutoffbuttonstate == true", otherwise value = 0
       cp5.getController("cutoffState").setColorBackground(cutoffButtonState ? color(40, 150, 90) : color(20, 49, 9)); // adjourn the controller's color
    break;

    case "detuneState":                                  // Same as above
       address = which_control;
       detuneButtonState = !detuneButtonState;
       value = detuneButtonState ? 1 : 0;
       cp5.getController("detuneState").setColorBackground(detuneButtonState ? color(40, 150, 90) : color(20, 49, 9));
       
    break;
    
    case "chorusState":
       address = which_control;
       chorusButtonState = !chorusButtonState;
       value = chorusButtonState ? 1 : 0;
       cp5.getController("chorusState").setColorBackground(chorusButtonState ? color(40, 150, 90) : color(20, 49, 9));
    
    break;
    
    case "distortionState":
       address = which_control;
       distortionButtonState = !distortionButtonState;
       value = distortionButtonState ? 1 : 0;
       cp5.getController("distortionState").setColorBackground(distortionButtonState ? color(40, 150, 90) : color(20, 49, 9));

    break;
  
// ------------------- Knobs ------------------//      

// Here we just need to adjourn the "value" variable. We'll use a logarithmic scale in most of the cases (see the logScale function at the bottom)

    case "cutOff":                                          
        address =  which_control;
        value = logScale((int)cutOff, 200, 40.0, 20000.0);
  
    break;
    
    case "resonance":
        address = which_control; 
        value = resonance; 
    break; 
    
    case "filterAttack":
        address = which_control; 
        value = logScale((int)filterAttack, 100, 0.1, 10); 
    break; 
    
    case "filterDecay":
        address = which_control; 
        value = logScale((int)filterDecay, 100, 0.1, 25);  
    break; 
    
    case "filterSustain":
        address = which_control; 
        value = logScale((int)filterSustain, 100, 0.1, 1); 
    break; 
    
    
// --> Chorus Knobs       

// As above

    case "chorusMix": 
       address = which_control;
       value = chorusMix;
    break;  
    
    case "chorusDepth": 
       address = which_control;
       value = chorusDepth;
    break; 
    
    case "chorusFeedback": 
       address = which_control;
       value = chorusFeedback;
    break; 
    
    case "chorusDelay": 
       address = which_control;
       value = chorusDelay;
    break; 

// --> Distortion Knobs

// As above

    case "distortionMix": 
       address = which_control;
       value = distortionMix;
    break;  
    
    case "distortionFilter": 
       address = which_control;
       value = distortionFilter;
    break; 
      

// --> Amp Knobs

// As above

    case "attack":
      address = which_control;
        value = logScale((int)attack, 100, 0.01, 0.99); 
    break;
    
    case "decay":
      address = which_control;
      value = logScale((int)decay, 100, 0, 4); 
    break;
    
    case "sustain":
      address = which_control;
      value = logScale((int)sustain, 100, 0.01, 0.99); 
    break;
    
    
    case "release":
      address = which_control;
      value = logScale((int)release, 100, 0.01, 10);   
    break;

// --> Other Knobs

// As above

    case "amp":
      address = which_control;
      value = amp;    
    break;    
    
    case "volume":
      address = which_control;
      value = volume;    
    break;
    
    case "pan":
      address = which_control; 
      value = pan; 
    break;

    case "detune":
        address =  which_control;
        value = detune;
    break;
    

// --> Dropdown Menu

// Here we adjourn the value with the dropdown menu's selection

    case "waveform":
      address = which_control;
      value = waveform + 1;
    break;  
    
  }  // Switch ends here

// If we made a selection through the switch, then we enter this conditional.

  if(address != null){
  OscMessage myMessage = new OscMessage("/" + address); // Send the oscmessage to the "\" +address parameter in SC
  myMessage.add(value);                                 // Add the value related to the controller to the message
  oscP5.send(myMessage, myRemoteLocation);              // Send the message at the "myRemoteLocation" address
  }
  
}


// Function to send OSC messages from Arduino to SuperCollider
void sendOscMessage(String address, float value) {
  OscMessage myMessage = new OscMessage(address);
  myMessage.add(value);
  oscP5.send(myMessage, myRemoteLocation);
}

// This function creates a logarithmic scale for the ADSR Envelopes and CutOff Knob
 
float logScale(int intValue, int maxRangeIn, float start, float end){
  float val;
  if(start == 0){                                                              // Handle the problematic case of -infinty 
    val = pow(10, (map (intValue, 0, maxRangeIn, 0, log(end)/log(10))));
  }
  else{
    val = pow(10, (map (intValue, 0, maxRangeIn, log(start)/log(10), log(end)/log(10))));
  };
  return val;
}
