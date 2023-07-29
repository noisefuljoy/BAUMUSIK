fork{

SynthDef(\perc_effect, {|in=0 out=0 amp=1.0 mix=0.0 decay=1|
	var sig,drysig, wetsig;
	drysig = In.ar(in, 1);
	wetsig = drysig;
	3.do{|i| var del = (i+1)*0.1;
		wetsig = CombL.ar(wetsig, del, SinOsc.kr(del*0.1).range(del*0.1,del),(i+1)*decay,0.4,wetsig*0.6);
	};
	sig = ((1-mix)*drysig) + (mix*wetsig);
	Out.ar(out, Pan2.ar(sig*amp, SinOsc.kr(LFNoise0.kr(0.8).range(0.1,80.0)).range(-0.25,0.25)));
	}).store;

SynthDef(\websdr, {|out=3 amp=1 gate=1|
		var env = EnvGen.ar(Env.adsr(15.0, 0.01,1, 45.0), gate, doneAction: 2);
		var input = SoundIn.ar([6,7]);

		input = Mix(input);

		Out.ar(out, input*env*amp ) }).store;


SynthDef('granulate_input', {|out=2,
	input1=0, input2=0, recGate=1,
	inAmp=1, outAmp=1, overlap=3, tFreq=20, tFreqMF=0, tFreqMD=0,
	rate=1, rateMF=0, rateMD=0,
	offset = 0, offsetMF=0, offsetMD=0|

	var input;
	var gDur, readPos, signal, writePos, grained, balance;

	var t, bufFrames, bufRateScale;
	var buf, bufdur;

	var tFreqMod = {
		SinOsc.ar(tFreqMF, Rand(0.0,2pi)) * tFreqMD;
	};

	var rateMod = {
		SinOsc.ar(rateMF, Rand(0.0,2pi)).range(rateMD.neg, rateMD);
		// SinOsc.ar(rateMF, Rand(0.0,2pi)).range(0, rateMD);
	};

	var offsetMod = {
		SinOsc.ar(offsetMF, Rand(0.0,2pi)).range(0, offsetMD);
		// LFDNoise3.ar(offsetMF).range(0,offsetMD(0.0))
	};


	tFreq = tFreq + tFreqMod.dup;
	rate = rate - rateMod.dup;


	bufFrames = 2**16;
	buf = {LocalBuf(bufFrames).clear}!2;
	bufdur = BufDur.ir(buf);


	writePos = Phasor.ar( end: bufFrames );


	t = Impulse.ar(tFreq);


	readPos =
	writePos
	- 64 // looks like a controlblocksize ------ why?
	/ bufFrames
	- offset
	- offsetMod.dup;
	// readPos = readPos.clip( 0, bufFrames - 64 / bufFrames );

	readPos = Wrap.ar(readPos, 0, 1);

/*
	(
		offset * bufFrames + 64 / SampleRate.ir
	).poll(10, \delaytime);
*/



	grained = GrainBufJ.ar(
		numChannels:1,
		loop: 1,
		trigger:t,
		dur: overlap / tFreq,
		sndbuf: buf,
		rate: rate,
		pos: readPos,
		interp: 4,
		pan: 0,
		envbufnum:-1
	);


	grained  = HPF.ar( grained, \grHpf.kr(40) );
	grained  = LPF.ar( grained, \grLpf.kr(15000) );




	input = SoundIn.ar([input1,input1]) * inAmp;

	// writing granulated + input back to grain buffer
	buf.do { |b i|

		BufWr.ar(grained[i] * \feedback.kr(0.3) + input[i], b, writePos)

		// RecordBuf has an option to overdub, might be of any use for big mess
		// RecordBuf.ar(
		// 	grained[i] * \feedback.kr(0.3) + input[i],
		// 	b,
		// 	recLevel: \recLevel.kr(1),
		// 	preLevel: \preLevel.kr(0),
		// );

	};
	signal = Mix([
		grained * \wet.kr(1),
		input * \dry.kr(1)
	]) * outAmp;
	signal = Mix(signal);
	//signal.tanh;
	signal = HPF.ar(signal, 40);

		Out.ar(out, Pan2.ar(signal) );


					}).store;




SynthDef('guitar_verb_one', { arg
	out=0,
	inBus,
	mix=0.3,
	inAmp=0.9,
	scaleDelays=1,
	inDiffusion=0.15,
	feedback=0.9,
	decay_sec=0.25,
	decay1_sec=0.25,
	predelay=0.01;

	//var input1 = \in.ar(0!2)!2;
	var signal;
	//var signalIn = [ \in1.ar([0]), \in2.ar([0])] ++ DC.ar(0).dup(3);
	var signalIn = In.ar(inBus, 2) ++ DC.ar(0).dup(3);
	//var signalIn = SoundIn.ar( (0..3) ) * inAmp;
	//var signalIn = input1 * inAmp;
	//var signalIn = [ Impulse.ar(0.5)* inAmp;  ] ++ DC.ar(0).dup(3);
	var tank;
	var sr = SampleRate.ir, sz = 4;
	var src, localin;
	var  times, dtimes;
	var l,r;
	var earlyDiffDTimes, earlyDiffSize=4;

	// signalIn = signalIn.rotate(3);

	// signalIn.debug(\signalIn________________);

	src = HPF.ar(signalIn, \inputHPF.kr(150));
	src = OnePole.ar(src, \inputLPF.kr(0.5));

	src = DelayN.ar(src, 0.01, predelay);

	times = [ 1447, 727, 613, 673, 1439, 2083, 2011, 1511, 1493, 1277, 2437, 2383, 2341, 997, 1061, 2039, 1997, 1481, 1627, 1129, 743, 983, 1091, 907, 541, 2393, 1801, 2081, 1787, 1453, 977, 2311, 691, 479, 2377, 1693, 1013, 1931, 1049, 2243, 839, 739, 1747, 601, 1823, 1123, 2467, 1297, 1613, 1361, 2207, 593, 619, 1709, 449, 937 ];

	earlyDiffDTimes = { times.removeAt(times.minIndex) } ! ( earlyDiffSize * src.size );

	l = times.size.div(2).collect({|i| times[i*2]}) * scaleDelays;
	r = times.size.div(2).collect({|i| times[i*2 + 1]}) * scaleDelays;




	dtimes = Routine{(earlyDiffDTimes ++ l ++ r).do { |it|it.yield}};
	// dtimes = Pseq( earlyDiffDTimes ++ l ++ r ).asStream;




	src.do { |it i|
		earlyDiffSize.do {
			var dt = dtimes.next / sr;
			src[i] = AllpassN.ar(src[i], dt, dt, inDiffusion);
		};

	};

	localin = LocalIn.ar(1);

	tank = sz.collect { |i|
		var dt0, dt1, dt2;

		localin = localin + src[i];

		dt0 = dtimes.next / sr;
		dt1 = dtimes.next / sr;
		dt2 = dtimes.next / sr;

		localin = AllpassC.ar(localin, dt0, dt0, decay_sec );
		localin = AllpassC.ar(localin, dt1, dt1, decay1_sec);


		localin = DelayC.ar(localin, dt2, dt2 - ( ControlDur.ir / sz )* LFNoise2.kr(0.3).range(0.9,1));
		localin = OnePole.ar(localin, \damping.kr(0.0) );

		// localin = localin * feedback;

	};


	tank.debug(\tank);
	LocalOut.ar( tank.last * feedback;);


	signal = 2.collect({|i|
		i = i*2;
		[
			tank[i] * ( "level_" ++ i ).asSymbol.kr(0),
			tank[i+1] * ( "level_" ++ ( i+1 ) ).asSymbol.kr(0)
		]
	}).sum;




	signal = tank.sum;
	signal = LeakDC.ar(signal);

	signal = signal.debug(\signal);
	//signal = signal * \tail.kr(1);

	signal = (signal * mix ) + (( signalIn!2) * (1-mix));
	//signal = Mix(signal);
	//signal;
	//signal = signal + signalIn;
	//LocalOut.ar(signal);


	Out.ar(out, signal!2);
}).store;



SynthDef(\sdr_sampler, {|out=0 gate=1 amp=0.5 att=15.0 rel=15.0 bufnum |
	var env, sig;
	env = EnvGen.ar(Env.adsr(att, 0.0, 1, rel), gate, doneAction: 2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), loop: 1);
	Out.ar(out, sig*env*amp);
	}).store;



SynthDef(\lofi_op,
	{   | shrateBus jitterBus gate=1|
		var nfilters = 6;
		var sig;
		var dw;

		var shrate = In.kr(shrateBus, 1);
		var jitter = In.kr(jitterBus, 1);
		var in = SoundIn.ar([1,2]);
		/*var in = BufRd.ar(2, buffer,
			phase: EnvGen.ar(Env.new( [0, BufFrames.kr(buffer) - 1 ],
				[
					BufDur.kr(buffer) *
					\stretch.kr(1).lag(4) *
					LFNoise1.kr(0.3).range(0.98, 1.02)
				]
			),
			gate:1),
			loop:0,
			interpolation: 4
		);*/

		var trigFreq = LFDNoise3.ar(shrate * \jitterScale.kr(1)!2).range(shrate * ( 1 - jitter ), shrate);

		var trig = Impulse.ar(trigFreq);

		sig = Latch.ar(in, trig);

		sig = Slew.ar(sig, \slewrate.kr(4410), \slewrate.kr);

		nfilters.do{ |i|
			//sig = LPF.ar(sig, ( shrate * \lpfscale.kr(0.25)).clip(100, SampleRate.ir * 0.45 ));
			sig = LPF.ar(sig, shrate * \lpfscale.kr( 0.5 ), mul: 1.1).atan;
		};

		//LinXFade2.ar(in, sig.neg, \drywet.kr(1))!2;
		dw = \drywet.kr(1);

		Mix([
			in * ( 1 - dw.abs ),
			sig * dw
		]) * EnvGen.kr(Env.adsr(0.01,0.3,0.5,1.0), gate, doneAction: 2);

		Out.ar(0, sig);


	}
).store;

SynthDef(\guitar_combdecaycontrol, {|in=0 out=2 decayBus gate=1|
		var decay = In.kr(decayBus, 1);
	var input = SoundIn.ar(in);

	var stereo = input;
	var mono = Mix(input);
	var env = EnvGen.ar(Env.adsr(0.1, 0.0,1.0, 5.0), gate, doneAction: 2);
	mono = PitchShift.ar(mono, 0.2, LFSaw.kr(LFNoise0.kr(0.1).range(0.2,1.5)).range(0.94,0.98),0.01,0.1,0.5,mono*0.5);
	mono = CombC.ar(mono, 0.2, SinOsc.kr(LFNoise2.kr(0.1).range(0.001,0.01)).range(0.01,0.2), decay, 0.1, mono*0.9);
	mono = CombC.ar(mono, 0.2, SinOsc.kr(LFNoise2.kr(0.1).range(0.005,0.05)).range(0.001,0.1), decay*0.5, 0.1, mono*0.9);

	//Out.ar(0, stereo!2);
	Out.ar(out, mono*env);
}).store;

SynthDef(\guitar_clean, {|in=0 out=2 decayBus gate=1|
		var decay = In.kr(decayBus, 1);
	var input = SoundIn.ar(in);

	var stereo = input;
	var mono = Mix(input).tanh;
	var env = EnvGen.ar(Env.adsr(0.1, 0.0,1.0, 5.0), gate, doneAction: 2);
	//mono = PitchShift.ar(mono, 0.2, LFSaw.kr(LFNoise0.kr(0.1).range(0.2,1.5)).range(0.94,0.98),0.01,0.1,0.5,mono*0.5);
	//mono = CombC.ar(mono, 0.2, SinOsc.kr(LFNoise2.kr(0.1).range(0.001,0.01)).range(0.01,0.2), decay, 0.1, mono*0.9);
	//mono = CombC.ar(mono, 0.2, SinOsc.kr(LFNoise2.kr(0.1).range(0.005,0.05)).range(0.001,0.1), decay*0.5, 0.1, mono*0.9);

	//Out.ar(0, stereo!2);
	Out.ar(out, mono*env);
}).store;


//granular patch
SynthDef(\ten_volume, {|out=0 in volume=1|
		var sig = In.ar(in, 2);
		Out.ar(out, [sig[0]*volume, sig[1]*volume]); }).store;

SynthDef(\sidechainer, {|out=0 inBus controlBus thresh=0.1 ratio=0.1 controlgain=0.5 volume=1|
			var in,control,sig1,sig2;
			in = In.ar(inBus, 2);
			control = In.ar(controlBus, 2);
			sig1 = Limiter.ar(Compander.ar(in[0],in[0],thresh,1,ratio,0.001,0.1,(1/ratio)*0.5,in[0]*0.5),1,0.001);
			sig2 = Limiter.ar(Compander.ar(in[1],in[1],thresh,1,ratio,0.001,0.1,(1/ratio)*0.5,in[1]*0.5),1,0.001);
			Out.ar(out, [sig1*volume, sig2*volume]); }).store;

SynthDef(\compressor, {|out=0 inBus thresh=0.1 ratio=0.1 gain=1|
			var in,control,sig1,sig2;
			in = In.ar(inBus, 2);
			sig1 = Limiter.ar(Compander.ar(in[0],in[0],thresh,1,ratio,0.001,0.1,1/ratio),1,0.001)*gain;
			sig2 = Limiter.ar(Compander.ar(in[1],in[1],thresh,1,ratio,0.001,0.1,1/ratio),1,0.001)*gain;
			Out.ar(out, [sig1, sig2]);
			//Out.ar(out, in);
		}).store;

SynthDef(\radiorecorder, {|in bufnum|
	var input = In.ar(in, 1);
	input = Limiter.ar(input,1, 0.001);
	//input = Compander.ar(input, input, 0.01, 1, 0.01, 0.001, 0.1,1000);
	input = Compander.ar(input, input, 0.001,1,0.01,0.001,0.1,200);
	//for hardware input
	//RecordBuf.ar(SoundIn.ar(in),bufnum);
	//for bus
	RecordBuf.ar(input,bufnum);
}).store;

//SYNTHS
//second generation sampler
SynthDef(\recrecorder, {|in bufnum|
	//for hardware input
	//RecordBuf.ar(SoundIn.ar(in),bufnum);
	//for bus
	var input = In.ar(in, 1);
	input = Compander.ar(input, input, 0.001,1,0.01,0.001,0.1,200);
	//input = Compander.ar(input, input, 0.001,1,0.01,0.001,0.1,50);
	RecordBuf.ar(input,bufnum,loop:0,doneAction:2);
}).store;
//sampleplayer

SynthDef(\radioplay, {|out amp mainvolBus start end release=0.005 trig=1 octave=1 reverse=1 vectorOut bufnum xpan= -0.5 ypan=1.0 nyquist sampleRate|
	//var start = In.kr(startBus, 1);
	var mainvol = In.kr(mainvolBus, 1);
	var loopdur = (end - start)/sampleRate*(1/octave);

	var trigger = EnvGen.kr(Env([1,0],[loopdur*0.95]),1);
	var env = EnvGen.ar(Env.adsr(loopdur*0.3,loopdur*0.1,1,loopdur*0.15),trigger,doneAction:2);
	var sig = BufRd.ar(1, bufnum, Phasor.ar(trig, BufRateScale.kr(bufnum)*reverse*octave,start+1000,end-1000 ),loop: 0) * env * amp;
	//var sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum),trig, loop: 1);
	//Out.ar(out, Pan2.ar(sig, LFNoise1.kr(Rand(0.8,3.2)).range(pan,pan+0.25)));
	//loopdur.poll;
	//Out.ar(out, Pan4.ar(sig, LFNoise2.kr(Rand(0.1,6.4)).range(xpan,xpan+1.0),LFNoise2.kr(Rand(0.1,14.4)).range(ypan,ypan+1.0,)));
	sig = LPF.ar(sig, nyquist);
	sig = HPF.ar(sig, 30,3);
	//Out.ar(out, Pan2.ar(sig*mainvol, LFNoise1.kr(Rand(0.8,3.2)).range(-0.5,0.5)));
	Out.ar(out, Pan2.ar(sig*mainvol,0) );
	Out.ar(vectorOut,sig);
}).store;

/*
SynthDef(\radioplaypattern, {|out=0 ampBus lengthBus start=0 endBus octave=1 trig=1 reverse=1 bufnum envbuf xpos=0 ypos=0 vectorOut nyquist|
	//var trigger = EnvGen.kr(Env([0,1,0],[0.001,0.001]),trig);
	var amp = In.kr(ampBus, 1);
	var end = In.kr(endBus, 1);
	var length = In.kr(lengthBus, 1);
	var env = Osc1.ar(envbuf, length*Rand(1.0,2.0), doneAction: 2);
	var sig = BufRd.ar(1, bufnum, Phasor.ar(trig, BufRateScale.kr(bufnum)*reverse*octave,start,end ),loop: 1) * env * 0.125;
	sig = LPF.ar(sig, nyquist);
	//Out.ar(out, Pan2.ar(sig*amp, 0));
	Out.ar(out, Pan2.ar(sig*amp, LFNoise0.kr(0.8).range(-1.0,1.0)));
	Out.ar(vectorOut, sig*2);
	}).store;
*/

//synth for granular patterns
SynthDef(\radioplaypattern, {|out=0 ampBus lengthBus start=0 endBus octave=1 t_trig=0 reverse=1 bufnum envbuf xpos=0 ypos=0 vectorOut nyquist|
	//var trigger = EnvGen.kr(Env([0,1,0],[0.001,0.001]),trig);
	var amp = In.kr(ampBus, 1);
	var end = In.kr(endBus, 1);
	var length = In.kr(lengthBus, 1);
		var env = Osc1.ar(envbuf, length);

	var aorB=ToggleFF.kr(t_trig);
    var startA=Latch.kr(start,aorB);
    var endA=Latch.kr(end,aorB);
    var startB=Latch.kr(start,1-aorB);
    var endB=Latch.kr(end,1-aorB);
    var crossfade=Lag.ar(K2A.ar(aorB),0.0001);

	var pos1 = Phasor.ar(aorB, BufRateScale.kr(bufnum)*reverse*octave,startA,end);
	var sig1 = BufRd.ar(1, bufnum, pos1,loop: 1);
	var pos2 = Phasor.ar((1 - aorB), BufRateScale.kr(bufnum)*reverse*octave,startB,end);
	var sig2 = BufRd.ar(1, bufnum, pos2,loop: 1);
	var totsig = (crossfade*sig1)+((1-crossfade)*sig2);
	//aorB.poll;
	//sig = LPF.ar(sig, nyquist);
	//Out.ar(out, Pan2.ar(sig*amp, 0));
	Out.ar(out, Pan2.ar(totsig * env * 0.125,LFNoise0.kr(0.8).range(-1.0,1.0)   ) );
	//Out.ar(out, Pan2.ar(sig*amp, LFNoise0.kr(0.8).range(-1.0,1.0)));
	Out.ar(vectorOut, totsig*2);
	}).store;

//for recording zitar
SynthDef(\zitarRecorder, {|in=0 onsetBus fftbuf recbuf|
var input = SoundIn.ar(in);
var chain = FFT(fftbuf, input);
var onsets = Onsets.kr(chain,0.15);
var amplitude = Amplitude.kr(input);

input = Compander.ar(input, input, 0.1,1,0.1,0.001,0.1,6);
//amplitude.poll;
		RecordBuf.ar(input, recbuf,loop:0,trigger:onsets);
Out.kr(onsetBus, onsets);
		//onsets.poll;

	}).store;


	//
	// SynthDef(\zitarRecorder, {|in=0 onsetBus fftbuf recbuf1 recbuf2|
	// 	var input = SoundIn.ar(in);
	// 	var chain = FFT(fftbuf, input);
	// 	var onsets = Onsets.kr(chain,0.15);
	// 	//var aorB=ToggleFF.kr(onsets);
	//
	// 	input = Compander.ar(input, input, 0.1,1,0.1,0.001,0.1,6);
	// 	//amplitude.poll;
	// 	RecordBuf.ar(input, recbuf,loop:0,trigger:onsets);
	// 	Out.kr(onsetBus, onsets);
	// 	//onsets.poll;
	//
	// }).store;


//for recording zitar
SynthDef(\busRecorder, {|in=0 amplitudeBus fftbuf recbuf|
var input = In.ar(in);
var chain = FFT(fftbuf, input);
var onsets = Onsets.kr(chain,0.15);
var amplitude = Amplitude.kr(input);

		input = Compander.ar(input, input, 0.1,1,0.1,0.001,0.1,6);
//amplitude.poll;
RecordBuf.ar(input, recbuf,loop:0,trigger:onsets);
//Out.kr(amplitudeBus, amplitude);

	}).store;


//3rd generation granulation
SynthDef(\regranulate, {|out=0 recOut ampBus lengthBus start=0 endBus octave=1 trig=1 reverse=1 bufnum envbuf pan=0 vectorOut nyquist|
	//var trigger = EnvGen.kr(Env([0,1,0],[0.001,0.001]),trig);
	var amp = In.kr(ampBus, 1);
	var end = In.kr(endBus, 1);
	var length = In.kr(lengthBus, 1);
	var env = Osc1.ar(envbuf, length, doneAction: 2);
	var sig = BufRd.ar(1, bufnum, Phasor.ar(trig, BufRateScale.kr(bufnum)*reverse*octave,start,end ),loop: 1) * env * 0.125;
	//var sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum),trig, loop: 1);
	sig = LPF.ar(sig, nyquist);
	//Out.ar(out, Pan2.ar(sig * amp));
	Out.ar(out, Pan2.ar(sig * amp, LFNoise0.kr(0.9).range(-1.0,1.0)) );
	Out.ar(recOut, sig*2);
	}).store;

SynthDef(\pumper, {|in out amp=0.5|
	var input = In.ar(in, 1);
	input = Compander.ar(input, input, 0.001,1, 0.001, 0.001,0.1,1000);
	//Out.ar(out, Pan2.ar(input*amp))
	Out.ar(out,  input * amp);
		}).store;


};