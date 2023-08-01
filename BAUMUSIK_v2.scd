

Server.killAll

MIDIIn.connectAll

SynthDef(\reverb, {
	arg inbus, out = 0, gate = 1, roomsize = 150, revtime = 2, damping = 0.6, inputbw = 0.5, spread = 15, drylevel = 1, earlyreflevel = 0.7, taillevel = 0.5, maxroomsize = 300, amp = 0.25;
	var source = In.ar(inbus,8);
	var reverb;
	//var env = Linen.kr(gate, 0.1, 1, 0.1, 2);
	reverb = GVerb.ar(source, roomsize, revtime, damping, inputbw, spread, drylevel, earlyreflevel, taillevel, maxroomsize);
	reverb = reverb * amp ;
	Out.ar(out, reverb!2);
	//XOut.ar(out,env,reverb);
}).store;

SynthDef(\reverb, {
	arg inbus, out = 0, gate = 1, roomsize = 150, revtime = 2, damping = 0.6, inputbw = 0.5, spread = 15, drylevel = 1, earlyreflevel = 0.7, taillevel = 0.5, maxroomsize = 300, amp = 0.25;
	var source = In.ar(inbus,8);
	var reverb;
	//var env = Linen.kr(gate, 0.1, 1, 0.1, 2);
	reverb = GVerb.ar(source, roomsize, revtime, damping, inputbw, spread, drylevel, earlyreflevel, taillevel, maxroomsize);
	reverb = reverb * amp ;
	Out.ar(out, reverb!2);
	//XOut.ar(out,env,reverb);
}).store;

~amp_bus = Bus.control(s, 1).set(0);
~amp_synth = Synth(\amp_follow, [\inbus, 0, \outbus, ~amp_bus]);
~clock = TempoClock.new(1);

~clock_spec = [0.1,12.0, -2, 0.01].asSpec;
~mul_spec = [0.125, 8.0, 1, 0.5].asSpec;
~rel_spec = [8.0, 0.0001, -4, 0.1].asSpec;
~scale_spec = [0, 6, \linear, 1].asSpec;
~mix_spec = [0.5,0.25, \linear, 0.1].asSpec;

~bellGroup = Group.new;
~reverbGroup = Group.after(~bellGroup);

~verbsynth = Synth(\reverb, [\inbus, ~bell_verb], ~reverbGroup);
//~verbsynth.free
~scale = Scale.ionian(\pythagorean);
~scale.cents.size;
~scale = Scale.phrygian;


Ndef(\kamfilter_zagen, {


	//var sig = SinOsc.ar(440*LFNoise0.kr(14.8).range(0.125,1.25), SinOsc.kr(10.5).range(-2pi, 2pi),0.25);
	var sig = SoundIn.ar(0);
	var drywet = SinOsc.kr(0.01).range(0.0,0.3);
	sig = CombC.ar(sig, 0.1,SinOsc.kr(0.01).range(0.001,0.1), 8.0, drywet, sig * (1 - drywet) );
	//sig = CombC.ar(sig, 0.2,0.2, 8.0, 0.4, sig * 0.6);


	sig = sig!2;

}).play;




Ndef(\zagen_met_zaagtand, {


	//var sig = SinOsc.ar(440*LFNoise0.kr(14.8).range(0.125,1.25), SinOsc.kr(10.5).range(-2pi, 2pi),0.25);
	var freq, hasFreq, sig;
	var input = SoundIn.ar(0);
	var amplitude = Amplitude.kr(input);
	# freq, hasFreq = Pitch.kr(input, ampThreshold: 0.02);

	//sig = SinOsc.ar(freq*6, SinOsc.kr(freq*0.5).range(-2pi, 2pi), amplitude);
    sig = Saw.ar(freq*3, amplitude);

	sig = FreeVerb.ar(sig, 0.3, 0.8, 0.6);
	//sig = CombC.ar(sig, 0.2,0.2, 8.0, 0.4, sig * 0.6);


	sig = sig!2;

}).play;



// trigger patterns from tools //
SynthDef(\amp_follow, {|outbus inbus=0|
	var sig = SoundIn.ar(inbus);
	var amplitude = Amplitude.kr(sig);
	Out.kr(outbus, amplitude); }).store;

SynthDef(\sine_vintage, {
//Crude simulation of old sinusoidal generators - with vibrato and high noise floor
	|out amp=0.05, freq=440, pan=0, atk = 0.001, sus = 0.25, rel = 0.01,

	vrate = 2, vdepth = 0.002, vdelay = 0.1, vonset = 0, vrateVariation = 0.1, vdepthVariation = 0.1 /*vibrato arguments*/,
	noiseAmp = 0.1|
	var env, sig, vibrato;
	env = EnvGen.kr(Env.linen(atk, sus, rel), doneAction:2);
	vibrato = Vibrato.kr(DC.kr(freq), DC.kr(vrate), DC.kr(vdepth), DC.kr(vdelay), DC.kr(vonset), DC.kr(vrateVariation), DC.kr(vdepthVariation));
	sig = SinOsc.ar(vibrato);
	sig = sig + PinkNoise.ar(noiseAmp);
	sig = sig * env;
	Out.ar(out, sig, pan, amp);
//By Zé Craum
}).store;

SynthDef(\harpsichord_pluck, {
	|out=0 amp=0.1, freq=440, pan=0, atk=0, rel=0, trig= 1, maxdelaytime= 0.2, decaytime= 7, coef= 0.1|
	var env, sig, delay;
	env = EnvGen.kr(Env.linen(atk, decaytime, rel), doneAction: Done.freeSelf);
	sig = PinkNoise.ar(amp); //Can use white noise here, but Pink is more realistic
	delay = freq.reciprocal;
	sig = Pluck.ar(sig, trig, maxdelaytime , delay , decaytime , coef ) //fundamental
	+ Pluck.ar(sig, trig, maxdelaytime , delay/2 , decaytime , coef ); //octave higher
	Out.ar(out, sig)
}).store;

SynthDef(\kalimba, {
	//Kalimba based on bank of ressonators
    |out = 0, freq = 440, ampBus, mix = 0.1, relMin = 2.5, relMax = 3.5|
    var amp,snd;
	amp = In.kr(ampBus, 1);
    // Basic tone is a SinOsc
    snd = SinOsc.ar(freq) * EnvGen.ar(Env.perc(0.3, Rand(relMin, relMax), 1, -8), doneAction: 2);
    // The "clicking" sounds are modeled with a bank of resonators excited by enveloped pink noise
    snd = (snd * (1 - mix)) + (DynKlank.ar(`[
        // the resonant frequencies are randomized a little to add variation
        // there are two high resonant freqs and one quiet "bass" freq to give it some depth
        [240*ExpRand(0.9, 1.1), 2020*ExpRand(0.9, 1.1), 3151*ExpRand(0.9, 1.1)],
        [-7, 0, 3].dbamp,
        [0.8, 0.05, 0.07]
    ], PinkNoise.ar * EnvGen.ar(Env.perc(0.001, relMin*0.001))) * mix);
	Out.ar(out, Mix(snd * amp) );
//By Nathan Ho aka Snappiz
//http://sccode.org/1-51l
}).store;





r = Routine({ inf.do{
	~amp_bus.get{|item| ~clock.tempo = ~clock_spec.map(item);

		if ( item > 0.001, {
			~synth_switch = 1;  "synth switch 1".postln;


			item.postln; }, { ~synth_switch = 0;
			//"synth switch 0".postln;

}); };  0.1.wait; }; }).play;


~kal_amp_bus = Bus.control(s, 1).set(0);

~synthRoutine = Routine({ inf.do{
	if ( ~synth_switch == 1, {
		"trigger synth".postln;

			~amp_bus.get{|item|
			Synth(\kalimba, [\ampBus, ~kal_amp_bus.index,\mix, ~mix_spec.map(item),\relMin, ~rel_spec.map(item)*0.9,\relMax, ~rel_spec.map(item),\decay, ~decay_spec.map(item), \freq, ~scale.cents[~scale_spec.map(item)] * ~mul_spec.map(item) ,\out, ~bell_verb], ~bellGroup);
	}; });
	0.1.wait; }; }).play(~clock);


Ndef(\clean_input, {|amp=1|
	var sig = SoundIn.ar(0) * 3;
	var sig2, sig3;
	//sig = Decimator.ar(sig,
	//sig = PitchShift.ar(sig, 0.3, 1.1,0.3,0.4, mul: 0.75, add: sig * 0.25);
	//sig2 = PitchShift.ar(sig, 0.3, 1.6,0.2,0.3, mul: 0.75, add: sig * 0.25);
	//sig3 = PitchShift.ar(sig, 0.3, 2.5,0.1,0.2, mul: 0.75, add: sig * 0.25);
	//sig = Mix([sig, sig2, sig3]);
	//sig = FreeVerb.ar(sig);
	sig = Pan2.ar(sig*amp);
	Out.ar(0, sig);
}).play;
/*
Ndef(\clean_input, {|amp=1|
	var sig = SoundIn.ar(0) * 3;
	var sig2, sig3;
	//sig = Decimator.ar(sig,
	sig = PitchShift.ar(sig, 0.3, 1.1,0.3,0.4, mul: 0.75, add: sig * 0.25);
	sig2 = PitchShift.ar(sig, 0.3, 1.6,0.2,0.3, mul: 0.75, add: sig * 0.25);
	sig3 = PitchShift.ar(sig, 0.3, 2.5,0.1,0.2, mul: 0.75, add: sig * 0.25);
	sig = Mix([sig, sig2, sig3]);
	sig = FreeVerb.ar(sig);
	sig = Pan2.ar(sig*amp);
	Out.ar(0, sig);
}).play;
*/
Ndef(\saw_pitchshiftdown, {|amp=1|
	var sig = SoundIn.ar(0);

	//sig = Decimator.ar(sig.tanh,20000, mul: 0.5, add: sig *0.5);
	sig = PitchShift.ar(sig, 0.2, 0.5,0.01,0.01, mul: 0.75, add: sig * 0.25);
	sig = PitchShift.ar(sig, 0.2, 0.25,0.05,0.03, mul: 0.75, add: sig * 0.25);


	//sig = CombC.ar(sig, 0.1,SinOsc.kr(0.01).range(0.001,0.1), 8.0, drywet, sig * (1 - drywet) );

	sig = FreeVerb.ar(sig);
	sig = Pan2.ar(sig*amp);
	Out.ar(0, sig*50);
}).play;

MIDIIn.connectAll;

MIDIdef.cc(\whitecontroller, {| val num chan src|
	[num,val,chan, src].postln;

	case { num == 0 } {
		~kal_amp_bus.set( (val/127)*0.4 );
		Ndef(\clean_input).set(\amp, val/127 );
		Ndef(\saw_pitchshiftdown).set(\amp, 1 - (val/127) );


	};


}, chan: 2);




r.stop;
~synthRoutine.stop;
