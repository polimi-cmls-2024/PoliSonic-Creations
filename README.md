# Voice-Modulated Synthesizer Plugin - Read Me

## Introduction
Welcome to the Voice-Modulated Synthesizer Plugin, a cutting-edge tool that integrates vocal recordings with synthesizer parameters to create unique soundscapes. This plugin allows you to use your voice to control various aspects of electronic music production, offering a new level of expression and creativity.

## Basic Functionality
- **Voice Integration**: Use your voice to influence synthesizer parameters like filter cutoffs, detuning, distortion, and chorus.
- **Real-Time Control**: Adjust parameters in real-time using MIDI devices, GUI knobs, and Arduino hardware controls.
- **Effects Processing**: Enhance your sounds with built-in effects like distortion and chorus through Juce.
- **Intuitive GUI**: Navigate an easy-to-use interface for waveform selection, sound modulation, and effects customization.

## Design and Topology
- **SuperCollider**: Acts as the sound synthesis engine, processing OSC messages to generate audio output.
- **MIDI Device**: Plays notes and sends MIDI data to SuperCollider.
- **Processing**: Provides the GUI for parameter adjustments and waveform selection.
- **Arduino**: Captures environmental noise and offers manual control over parameters.
- **Juce**: Adds audio effects to the synthesized sound.

## GUI Design
- **Waveform Selection Area**: Choose between Sine, Square, and Sawtooth waves.
- **Sound Modulation Controls**: Adjust ADSR envelope parameters for dynamic expression.
- **Effects Central Hub**: Fine-tune effects like Filter, Detune, Chorus, and Distortion.
- **Recording and Rhythm Application Module**: Record vocal rhythms and apply them to modulate sound parameters.
- **Loop and Playback Functionality**: Loop recorded rhythms for continuous playback and modulation.

## Getting Started
1. Connect your MIDI device and Arduino to your computer.
2. Launch the GUI in Processing and run the SuperCollider code.
3. Select your desired waveform and adjust the ADSR envelope to shape your sound.
4. Record your voice using the Record Button and apply the rhythm to modulate parameters.
5. Experiment with the effects to find your unique sound.

Enjoy exploring the vast possibilities of sound design with your voice as the conductor!
