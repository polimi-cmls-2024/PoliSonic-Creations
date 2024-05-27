Server.killAll; // kill the Server 
s.reboot; // reboot the server
MIDIClient.init; // scan the available MIDI Input
MIDIIn.connectAll; // connect MIDI Input

(
// ============================================ DEFINITIONS ==================================================== //

// In this section we define the core elements of our design: the actual synthesizer, the buses and the FX Chain.

// -------------- BUSES DEFINITION --------------------- //

~fxBus = Bus.audio(s, 2); // Audio FX Bus : This will the sound coming from our oscillators, and will bring it to the LPF

// -------------- SYNTH DEFINITION --------------------- //
/*
Here we define the main SynthDef that generates the sound of our synthesizer:
1. Waveform Generation: It generates three types of waveforms: sinusoidal (`sourceSin`), square (`sourceSquare`), and sawtooth (`sourceSaw`). The frequency (`freq`) and amplitude (`amp`) of these waveforms can be controlled.
2. Detuning: It creates detuned versions of these waveforms (`detunedSin`, `detunedSquare`, `detunedSaw`). Detuning is used to create a thicker, richer sound by slightly varying the frequency of multiple waves of the same type.
3. Mixing: It mixes the original and detuned waveforms together (`mixed`). This is done by simply adding the waveforms together.
4. Envelope Generation**: It creates an envelope (`env`) using the ADSR (Attack, Decay, Sustain, Release) model. This envelope is used to shape the amplitude of the sound over time. 
5. Filter Envelope Generation: It creates the filter's envelope ('filterEnv'), using the ADSR envelope 
6. Filtering: If `lpfOn` is set to 1, it applies a low-pass filter (`RLPF`) to the mixed signal. The cutoff frequency of this filter can be modulated by an envelope (`filterEnv`). This can be used to create dynamic changes in the timbre of the sound.
7. Output: Finally, it sends the signal to the audio output (`Out.ar`). The signal is panned based on the `pan` argument, allowing for stereo effects.
*/

SynthDef(\dynamicLPF, { |freq=440, amp=0.1, gate=0, detune=0.1, cutOff = 500, lpfOn=0, detuneActive=0, out= 0, sin=0, square=0, saw=0, attack=0.01, decay=0, sustain=1, release=0.0, volume = 1, pan = 0.0, resonance = 1.0, filterAttack = 0.01, filterSustain = 1.00, filterDecay = 0.0, filterRelease = 0.0|
    var sourceSin, sourceSquare, sourceSaw, env, detunedSin, detunedSquare, detunedSaw, mixed, filtered, control, sig, filterEnv;

	sourceSin = SinOsc.ar(freq, mul:amp*0.3) * sin; // sinusoid wave generation
	sourceSquare = Pulse.ar(freq, mul:amp*0.3) * square; // square wave generation
	sourceSaw = Saw.ar(freq, mul:amp*0.3) * saw; // saw wave generation
	env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction:2);
	filterEnv = EnvGen.ar(Env.adsr(filterAttack, filterDecay, filterSustain, filterRelease), doneAction:2); 	
	detunedSin = SinOsc.ar(freq * (1 + detune), mul:amp*0.3) * sin * detuneActive;
	detunedSquare = Pulse.ar(freq * (1 + detune), mul:amp*0.3) * square * detuneActive; // second square wave for detuning if detuneActive=1
	detunedSaw = Saw.ar(freq * (1 + detune), mul:amp*0.3) * saw * detuneActive ;
    	mixed = sourceSin + sourceSquare + sourceSaw + detunedSin + detunedSquare + detunedSaw; // mix of the two square waves
	control = lpfOn.lag(0.1); // lag for a smoother change
	filtered = Select.ar(control, [mixed, RLPF.ar(mixed, cutOff * filterEnv, resonance)]); // filter is applied if lpfOn=1
	sig = filtered * env * volume;
	Out.ar(out, Pan2.ar(sig, pan)); // output stereo
}).add;

// ---------------- FX CHAIN DEFINITION ---------------------- //

// FX Chain

// It defines a Synth containing an fxChain. This FX chain has an input bus that we can chose (so we could potentially attach it anywhere we want)
//   and as an output we have the "plugin" variable, which has the fx lined up in series. We will be able to bypass those plugins through the fx1 & fx2 parameters

SynthDef(\fxChain, { |bus, fx1 = 2, mix, fx2 = 2|
	var plugin = In.ar(bus, 2);
	plugin = VSTPlugin.ar(plugin, 2, fx2, id:\distortion);
	plugin = VSTPlugin.ar(plugin, 2, fx1, id:\chorus);
    Out.ar(bus, plugin);

}).add;

// After adding the synthesizer to the server, we instantiate an instance of it, called ~fxSynth. This instance is placed on the ~fxBus declared before, 
// and it's positioned at the end of it through the use of the "addAction" parameter. 

~fxSynth = Synth(\fxChain, [\bus, ~fxBus], addAction: \addToTail);

// Now we route the ~fxBus to the main output bus through the following SynthDef, which is instantly allocated. Again, this is added to the Tail of the Group 1

SynthDef(\output, { arg in = 0, out = 0;
    Out.ar(out, In.ar(in, 2))
	}).play(1 ,[\in, ~fxBus, \out, 0], addAction: \addToTail);

// The plugin controller is then instantiated. Since we implemented two fx inside the same synthDef, we need to use the ".collect" method to create one plugin controller per effect.
	~fx = VSTPluginController.collect(~fxSynth);
// Open the vst Plugins
	~fx.distortion.open("SubDominant.vst3");
	~fx.chorus.open("basicChorus.vst3");

// ============================================ MIDI NOTE ON/OFF ==================================================== //
/*
Here we handle MIDI note on and off messages:
1. MIDI Channel and Notes Initialization: It first sets the MIDI channel (`~midiChannel`) to 0 and initializes an array (`~notes`) with 128 elements, representing the 128 possible MIDI notes.
2. MIDI Note On Handling: The `MIDIdef.noteOn` function is used to define what happens when a MIDI note on message is received. If the channel of the incoming MIDI message matches `~midiChannel`, a new Synth (`~notes[note]`) is created based on the `dynamicLPF` SynthDef defined earlier. The parameters of the Synth are set based on various variables.
3. MIDI Note Off Handling: The `MIDIdef.noteOff` function is used to define what happens when a MIDI note off message is received. If the channel of the incoming MIDI message matches `~midiChannel`, the gate of the corresponding Synth is set to 0, which should trigger the release stage of the envelope. The Synth is then freed and the corresponding element in the `~notes` array is set to nil.
*/

~midiChannel = 0; 
~notes = Array.newClear(128); 
MIDIdef.noteOn(\startSynth, { |vel, note, chan|

	if(chan == ~midiChannel, {
        ~notes[note] = Synth.new(
			\dynamicLPF,
			[
				\attack, ~attackTime,
				\decay, ~decayTime,
				\sustain, ~sustainLevel,
				\release, ~releaseTime,
				\amp, ~amp,
				\freq, note.midicps,
				\volume, ~volume,
				\pan, ~pan,
				\gate, 1,
				\lpfOn, ~filterOn,
				\cutOff, ~cutOff,
				\detuneActive, ~detuneOn,
				\detune, ~detune,
				\sin, ~sin,
				\square, ~square,
				\saw, ~saw,
				\out, ~fxBus,
				\resonance, ~resonance,
				\filterAttack, ~filterAttack,
				\filterDecay, ~filterDecay,
				\filterSustain, ~filterSustain,
				\filterRelease, ~filterRelease
			])
	});
}, chan:~midiChannel);

// Define a function to stop the Synth when a MIDI note is released
MIDIdef.noteOff(\stopSynth, { |vel, note, chan|
    if(chan == ~midiChannel, {
		~notes[note].set(\gate, 0);
		~notes[note].isPlaying.free;
		~notes[note] = nil;
    });
}, chan:~midiChannel);


// ============================================ OSC Communication with Processing ==================================================== //
/*
In this section we handle Open Sound Control (OSC) messages that are sent from the GUI to SuperCollider:
1. OSC Address Initialization: Initially we set up the OSC communication by defining the network address (`n = NetAddr("127.0.0.1")`) to which OSC messages will be sent.
2. OSC Message Handling: The `OSCFunc` function is used to define what happens when an OSC message is received. The OSC message is expected to have the address `/address` and to be sent to the network address `n` on port `57120`.
3. Value Update: The first argument of the OSC message (`msg[1]`) is used to update the value that the specific `OSCFunc` has to change. 
4. Synth Update: For each active Synth in `~notes`, it updates the parameter that corresponds to the value that has been updated.
*/

n = NetAddr("127.0.0.1"); // set the receiving address for OSC Messages

// -------------- Waveform Selection -------------- //
/*
Here we select the waveform type: the first argument of the OSC message (`msg[1]`) is used to select the waveform:
1. If `~waveform` is `1`, it sets `~sin` to `1` and `~square` and `~saw` to `0`, indicating that a sinusoidal waveform should be generated.
2. If `~waveform` is `2`, it sets `~square` to `1` and `~sin` and `~saw` to `0`, indicating that a square waveform should be generated. 
3. If `~waveform` is `3`, it sets `~saw` to `1` and `~sin` and `~square` to `0`, indicating that a sawtooth waveform should be generated.
*/

~waveform = 0;
~sin = 0;
~square = 0;
~saw = 0;
OSCFunc({ |msg, time, addr, recvPort|
    ~waveform = msg[1];
    if(~waveform == 1, {
		~sin = 1;
		~square = 0;
		~saw = 0;
        ~notes.do { |synth|
            if(synth.notNil, {
                synth.set(\sin, ~sin, \square, ~square, \saw, ~saw);
            });
        };
    }, {
        if(~waveform == 2, {
			~sin = 0;
		    ~square = 1;
			~saw = 0;
            ~notes.do { |synth|
                if(synth.notNil, {
                    synth.set(\sin, ~sin, \square, ~square, \saw, ~saw);
                });
            };
        }, {
            if(~waveform == 3, {
				~sin = 0;
				~square = 0;
				~saw = 1;
                ~notes.do { |synth|
                    if(synth.notNil, {
                        synth.set(\sin, ~sin, \square, ~square, \saw, ~saw);
                    });
                };
            });
        });
    });
}, '/waveform', n, 57120);

// -------------- Master volume -------------- //
// Here we control the master volume through a knob in the GUI.

~volume = 1;
OSCFunc({|msg, time, addr, recvPort|
	~volume = msg[1];
	~notes.do{|synth|
		if(synth.notNil, {
			synth.set(\volume, ~volume);
		});
	};
}, '/volume', n, 57120);

// -------------- VOCAL AMPLITUDE -------------- //
// Here we control the amplitude of multiple Synths in real-time. The amplitude of the sound is controlled by the amplitude of a real-time vocal recording.

~amp = 1;
OSCFunc({|msg, time, addr, recvPort|
	~amp = msg[1];
	~notes.do{|synth|
		if(synth.notNil, {
			synth.set(\amp, ~amp);
		});
	};
}, '/amp', n, 57120);

// -------------- PANNING -------------- //
// Here we control the panning through a knob in the GUI.

~pan = 0.0;
OSCFunc({|msg, time, addr, recvPort|
	~pan = msg[1];
	~notes.do{|synth|
		if(synth.notNil, {
			synth.set(\pan, ~pan);
		});
	};
}, '/pan', n, 57120);

// -------------- DETUNE ON/OFF -------------- //
// Here we control the detune state through a button in the GUI: if ~detuneOn = 1 then the detune it's turned ON, otherwise it's turned OFF.

OSCFunc({|msg, time, addr, recvPort|
	~detuneOn = msg[1];
	~notes.do{|synth|
		if(synth.notNil, {
			synth.set(\detuneActive, ~detuneOn);
		});
	};
}, '/detuneState', n, 57120);

// -------------- DETUNE AMOUNT -------------- //
// Here we control the detune amount through a knob in the GUI.

OSCFunc({|msg, time, addr, recvPort|
	~detune = msg[1];
	~notes.do{|synth|
		if(synth.notNil, {
			synth.set(\detune, ~detune);
		});
	};
}, '/detune', n, 57120);

// ---------------- ADSR FOR WAVEFORMS --------------- //
// Here we control the parameters of an ADSR (Attack, Decay, Sustain, Release) envelope for waveforms thorugh four knobs in the GUI. 

// Attack time
~attackTime = 0.05;
OSCFunc({|msg, time, addr, recvPort|
	~attackTime = msg[1];
}, '/attack', n, 57120);

// Decay time
~decayTime = 0.0;
OSCFunc({|msg, time, addr, recvPort|
	~decayTime = msg[1];
}, '/decay', n, 57120);

// Sustain level
~sustainLevel = 1.0;
OSCFunc({|msg, time, addr, recvPort|
	~sustainLevel = msg[1];
}, '/sustain', n, 57120);

// Release level
~releaseTime = 1.0;
OSCFunc({|msg, time, addr, recvPort|
	~releaseTime = msg[1];
}, '/release', n, 57120);

// ---------------- FILTER ON/OFF --------------- //
// Here we control the low-pass filter state through a button in the GUI: if ~filterOn = 1 then the filter is ON, otherwise it turned OFF.

OSCFunc({|msg, time, addr, recvPort|
	~filterOn = msg[1];
	~notes.do{|synth|
		if(synth.notNil, {
		synth.set(\lpfOn, ~filterOn);
		});
	};
}, '/cutoffState', n, 57120);

// ---------------- FILTER CUTOFF --------------- //
// Here we control the cutoff value through a knob in the GUI.

OSCFunc({|msg, time, addr, recvPort|
	~cutOff = msg[1];
	~notes.do{|synth|
		if(synth.notNil, {
		synth.set(\cutOff, ~cutOff);

		});
	};
}, '/cutOff', n, 57120);

// ---------------- FILTER RESONANCE --------------- //
// Here we control the resonance amount through a knob in the GUI.

OSCFunc({|msg, time, addr, recvPort|
	~resonance = msg[1];
	~notes.do{|synth|
		if(synth.notNil, {
		synth.set(\resonance, ~resonance);
		});
	};
}, '/resonance', n, 57120);

// ---------------- ADSR FOR FILTER --------------- //
// Here we control the parameters of an Attack, Decay, Sustain envelope for the low-pass filter thorugh three knobs in the GUI. 

// Filter Env Attack
OSCFunc({|msg, time, addr, recvPort|
	~filterAttack = msg[1];
	~notes.do{|synth|
		if(synth.notNil, {
		synth.set(\filterAttack, ~filterAttack);
		});
	};
}, '/filterAttack', n, 57120);

// Filter Env Decay
OSCFunc({|msg, time, addr, recvPort|
	~filterDecay = msg[1];
	~notes.do{|synth|
		if(synth.notNil, {
		synth.set(\filterDecay, ~filterDecay);
		});
	};
}, '/filterDecay', n, 57120);

// Filter Env Sustain
OSCFunc({|msg, time, addr, recvPort|
	~filterSustain = msg[1];
	~notes.do{|synth|
		if(synth.notNil, {
		synth.set(\filterSustain, ~filterSustain);
		});
	};
}, '/filterSustain', n, 57120);

// ------------- JUCE FXs ------------------ //
// Here we control the parameters of the imported JUCE Effects through buttons and knobs in the GUI. In particular we use the (`VSTPluginController.set(parameter, value)`) function to update the value of a specific parameter of the imported effect with the new value sent from the GUI.

// ------------- CHORUS ON/OFF ------------------ //
// Here we control the chorus state through a button in the GUI: if ~chorusToggle = 1 then the BYPASS is activated so the chorus is turned OFF, otherwise the BYPASS is deactivated so the chorus is turned ON.

OSCFunc({|msg, time, addr, recvPort|
	~chorusToggle = msg[1];
	~fxSynth.set(\fx1, ~chorusToggle);
}, '/chorusState', n, 57120);

// ------------- CHORUS MIX ------------------ //
// Here we control the chorus mix amount through a knob in the GUI.

~chorusMix = 1;
OSCFunc({|msg, time, addr, recvPort|
	~chorusMix = msg[1];
	~fx.chorus.set(4, ~chorusMix);
}, '/chorusMix', n, 57120);

// ------------- CHORUS FEEDBACK ------------------ //
// Here we control the chorus feedback amount through a knob in the GUI.

~chorusFeedback = 0;
OSCFunc({|msg, time, addr, recvPort|
	~chorusFeedback = msg[1];
	~fx.chorus.set(3, ~chorusFeedback);
}, '/chorusFeedback', n, 57120);

// ------------- CHORUS DELAY ------------------ //
// Here we control the chorus delay amount through a knob in the GUI.

~chorusDelay= 0;
OSCFunc({|msg, time, addr, recvPort|
	~chorusDelay = msg[1];
	~fx.chorus.set(2, ~chorusDelay);
}, '/chorusDelay', n, 57120);

// ------------- CHORUS DEPTH ------------------ //
// Here we control the chorus depth amount through a knob in the GUI.

~chorusDepth = 0;
OSCFunc({|msg, time, addr, recvPort|
	~chorusDepth = msg[1];
	~fx.chorus.set(1, ~chorusDepth);
}, '/chorusDepth', n, 57120);

// ------------- DISTORTION ON/OFF ------------------ //
// Here we control the distortion state through a button in the GUI: if ~distortionToggle = 1 then the BYPASS is activated so the distortion is turned OFF, otherwise the BYPASS is deactivated so the distortion is turned ON.

OSCFunc({|msg, time, addr, recvPort|
	~distortionToggle = msg[1];
	~fxSynth.set(\fx2, ~distortionToggle);
}, '/distortionState', n, 57120);

// ------------- DISTORTION MIX ------------------ //
// Here we control the distortion mix amount through a knob in the GUI.

~distortionMix = 1;
OSCFunc({|msg, time, addr, recvPort|
	~distortionMix = msg[1];
	~fx.distortion.set(8, ~distortionMix);
}, '/distortionMix', n, 57120);

// ------------- DISTORTION FILTER ------------------ //
// Here we control low-pass filter cutoff of the distortion through a knob in the GUI.

~distortionFilter = 1;
OSCFunc({|msg, time, addr, recvPort|
	~distortionFilter = msg[1];
	~fx.distortion.set(4, ~distortionFilter);
}, '/distortionFilter', n, 57120);

)
