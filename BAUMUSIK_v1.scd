





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


Ndef(\ratel_melodie