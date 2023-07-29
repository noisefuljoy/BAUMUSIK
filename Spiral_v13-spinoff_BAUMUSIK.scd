/*
morse frequency with USB
10108.46
10111.18
14073.47

CW
simple morse code
10111.26
10122.97
10123.02

10115.25

complex morse code
10100.83

aether noise
10136.47

14073.47

*/


(
fork{

Require("synthdefs");

~sdr_files = "/home/numina/repositories/Spiral-performance/sdr-samples/*.wav".pathMatch;
~sdr_samples = ~sdr_files.collect({|i| Buffer.read(s, i); });


~overlap_spec = [2.0,0.0001,\linear,0.001].asSpec;
//~tfreq_spec = [0.1,22050*0.01,\linear,0.001].asSpec;
	~tfreq_spec = [5,150,\linear,0.001].asSpec;
~offset_spec = [0.01,1,\linear,0.001].asSpec;

~ratemf_spec = [0.0,2000,\linear,0.001].asSpec;
~ratemd_spec = [0.0,1.0,\linear,0.001].asSpec;
~trigmf_spec = [0.01,200,\linear,0.001].asSpec;
~trigmd_spec = [0.01,200,\linear,0.001].asSpec;
~rate_spec = [0.1,1.05,\linear,0.001].asSpec;


~fcrickets_trigSpec = [58.82, 400.0, \linear, 0.01].asSpec;
~cicada_trigSpec = [0.001, 80.0, \linear, 0.01].asSpec;

~shrate_spec = [ 15000, 500, \linear, 0.001].asSpec;
~jitter_spec = [0.01, 0.9, \linear].asSpec;


~shrateBus = Bus.control(s, 1).set(15000);
~jitterBus	= Bus.control(s, 1).set(0.01);

~fcricket_trigBus = Bus.control(s, 1).set(58.82);
~cicada_trigBus = Bus.control(s, 1).set(0.2);


~guitarcomb_decayBus = Bus.control(s, 1).set(1.0);


~onset_bus = Bus.control(s, 1);

1.0.wait;

MIDIIn.connectAll;
2.0.wait;

~grain_footswitcher = 0;


~sdr_samp_group = Group.new;
~websdr_group = Group.new;
~lofi_group = Group.new;
~guitar_group = Group.new;
~guitarclean_group = Group.new;
~insects = Group.new;

~granul_group = Group.new;
~pretty_verb_group = Group.after(~granul_group);
~pretty_verb_input = Bus.audio(s, 2);





Synth(\guitar_verb_one, [\inBus, ~pretty_verb_input,\feedback, 0.35,\out, 2], ~pretty_verb_group);


// comb percussion ticks
~percGroup = Group.tail(~synthGroup);

~percBus = Bus.audio(s, 1);
~percGrainBus = Bus.audio(s, 1);

	~phasemIndexBus = Bus.control(s, 1).set(0);
	~phaseModFreq = Bus.control(s, 1).set(8);

	~phasemIndexSpec = [0.01, 1000.0, \linear, 0.01].asSpec;
	~freqRange = [100, 800, \linear, 10].asSpec;
	~releaseRange = [0.1,1.0, 5, 0.001].asSpec;
	~relmulSpec = [1.0, 10.0, \exp, 0.001].asSpec;
~ampRange = [0.25, 1.0, \linear, 0.001].asSpec;
~decRange = [0.001, 30.0, \exp, 0.001].asSpec;
	~relMul = 1;


~combPerc = Synth(\perc_effect, [\in, ~percBus,\out, 0], ~percGroup, \addAfter);
~grainPerc = Synth(\grain_perc, [\in, ~percGrainBus, \envbuf, ~wenv], ~percGroup, \addAfter);




//~pretty_verb_group.freeAll
~sdr_count = 1;
~grain_settings = 4;





(
MIDIdef.cc(\whitecontroller, {| val num chan src|
	[num,val,chan, src].postln;


	case
	{ num == 105 }
	{
		if ( val == 127, {
					"web sdr on".postln;
					Synth(\websdr, [\out, 3], ~websdr_group); }, {
					"web sdr off".postln;
					~websdr_group.set(\gate, 0);

				});

			}
	//play button for sdr emergency samples
	{ num == 103 } {
	if ( val == 127, {
			if ( ~sdr_count != 1, { ~sdr_count = ~sdr_count + 1; }, { ~sdr_count = 0;      });
					Synth(\sdr_sampler, [\bufnum, ~sdr_samples[~sdr_count+3], \out, 3], ~sdr_samp_group );
			("playing sdr sample nr : "++~sdr_count).postln;
		},
		{
			~sdr_samp_group.set(\gate, 0);
			"switching the sdr sampler off".postln;

		});
		}
	{ num == 110 } {
				if ( ~grain_footswitcher == 1, { ~grain_footswitcher = 0; "grainfootswitcher 0".postln; },
					{ ~grain_footswitcher = 1;  "grainfootswitcher 1".postln; });

	};

	// S toggle buttons 48 - 55
	case
	{ num == 48 } {

	if ( val == 127, {
					"granulate guitar input".postln;
	Synth(\granulate_input, [\input1, 0, \input2, 0, \out, ~pretty_verb_input], ~granul_group);



 }, {
					"granulate guitar input off".postln;
				~granul_group.freeAll;


			});

		}
	{ num == 49 } {
				if ( val == 127, {
					Synth(\lofi_op, [\shrateBus, ~shrateBus.index, \jitterBus, ~jitterBus.index], ~lofi_group ); "lofi op1 on".postln;  },
					{ ~lofi_group.set(\gate, 0); "lofi op1 off".postln;   });

			}

	{ num == 50 } {
			if ( val == 127, {
					Synth(\guitar_combdecaycontrol, [\in, 0,\decayBus, ~guitarcomb_decayBus.index], ~guitar_group);    }, {
					~guitar_group.set(\gate, 0);
				});


			}
	{ num == 51 } {
			if ( val == 127, {
					Synth(\guitar_clean, [\in, 0,\decayBus, ~guitarcomb_decayBus.index], ~guitarclean_group);    }, {
					~guitarclean_group.set(\gate, 0);
				});


			}
	{ num == 52 } { }
	{ num == 53 } { }
	{ num == 54 } { if ( val == 127, { 	~fieldcricket = Synth(\fieldcricket, [\tfreqBus, ~fcricket_trigBus.index, \recout, 500], ~insects); }, { ~fieldcricket.set(\gate, 0); }); }
	{ num == 55 } { if ( val == 127, { 	~cicada_3calls = Synth(\cicada_3calls, [\tfreqBus, ~cicada_trigBus.index, \recout, 500], ~insects); }, { ~cicada_3calls.set(\gate, 0); }); };


	// M toggle buttons 40 - 47
	case
	{ num == 40 } {

		if ( ~grain_settings != 4, { ~grain_settings = ~grain_settings + 1; }, { ~grain_settings = 0; });

		case
		{ ~grain_settings == 0 } {   "0 - normal setting".postln;
			~granul_group.set('offset', 0.158, 'wet', 1.0, 'rate', 1.01, 'tFreq', 14.127, 'grLpf', 18851.464465481, 'rateMF', 0.0, 'tFreqMF', 0.01, 'tFreqMD', 0.01,'rateMD', 0.0, 'overlap', 0.8, 'dry', 0.0, 'feedback', 0.34928932685149);

			~pretty_verb_group.set(\feedback, 0.1, \mix, 0.1);
		}
		{ ~grain_settings == 1 } { "2 - fragmented, high - piezo tapping + strum".postln;
			~granul_group.set('offset', 0.0, 'wet', 0.6503937007874, 'rate', 2.2493240605221, 'tFreq', 1.0, 'grLpf', 18851.464465481, 'rateMF', 20.472, 'tFreqMF', 17.884, 'tFreqMD', 0.1, 'rateMD', 0.5, 'overlap', 5.0, 'dry', 0.496062992126, 'feedback', 0.5);

			~pretty_verb_group.set(\feedback, 0.35, \mix, 0.05);
		}

		{ ~grain_settings == 2 } { "2 - bar 4 - drone".postln;
			~granul_group.set('offset', 0.1, 'wet', 1.0, 'rate', 0.25035754779845, 'tFreq', 4.127, 'grLpf', 18851.464465481, 'rateMF', 220.472, 'tFreqMF', 7.884, 'tFreqMD', 0.01,'rateMD', 0.0, 'overlap', 2.072, 'dry', 0.0, 'feedback', 0.84928932685149);

					~pretty_verb_group.set(\feedback, 0.5, \mix, 0.25);
		}
		{ ~grain_settings == 3 } { "chords after drone".postln;
			~granul_group.set('offset', 0.1, 'wet', 0.1, 'rate', 0.25035754779845, 'tFreq', 4.127, 'grLpf', 18851.464465481, 'rateMF', 220.472, 'tFreqMF', 7.884, 'tFreqMD', 0.01,'rateMD', 0.0, 'overlap', 2.072, 'dry', 0.9, 'feedback', 0.84928932685149);

					~pretty_verb_group.set(\feedback, 0.9, \mix, 0.3);
		}

	{ ~grain_settings == 4 }  {"guitar impro setting 1".postln;
			~granul_group.set('offset', 0.189, 'wet', 1.0, 'rate', 2.2493240605221, 'tFreq', 397.379, 'grLpf', 18851.464465481,  'rateMF', 20.472,'tFreqMF', 17.884, 'tFreqMD', 0.1, 'rateMD', 0.5, 'overlap', 0.121, 'dry', 0.0, 'feedback', 0.001);

				~pretty_verb_group.set(\feedback, 0.001, \mix, 0.01);
				};

			}
	{ num == 41 } { }
	{ num == 42 } { }
	{ num == 43 } { }
	{ num == 44 } { }
	{ num == 45 } { }
	{ num == 46 } { }
	{ num == 47 } { };

	// R toggle buttons 32 - 39
	case
	{ num == 32 } { }
	{ num == 33 } { }
	{ num == 34 } { }
	{ num == 35 } { }
	{ num == 36 } { }
	{ num == 37 } { }
	{ num == 38 } { }
	{ num == 39 } { };



	// pots 56 - 63
	case
	{ num == 56 } { ~pretty_verb_group.set('mix', (val/127) );  }
	{ num == 57 } { }
	{ num == 58 } { }
	{ num == 59 } { }
	{ num == 60 } { }
	{ num == 61 } { ~combPerc.set(\decay, ~decRange.map(val/127);  );  }
	{ num == 62 } { ~fcricket_trigBus.set( ~fcrickets_trigSpec.map(val/127)); }
	{ num == 63 } { ~cicada_trigBus.set( ~cicada_trigSpec.map(val/127)); };

	// faders 0 - 7
	case
	{ num == 0 } { ~granul_group.set(\dry, (val/127) , \wet, (1 - (val/127) )); }
	{ num == 1 } { }
	{ num == 2 } { }
	{ num == 3 } { }
	{ num == 4 } { }
	{ num == 5 } { ~combPerc.set(\mix, val/127); }
	{ num == 6 } { }
	{ num == 7 } { };



}, chan: 2);
	);




(

fork {
	// Require("D:/Dropbox/PROJECTS/SC_performances/tenori-on/Ansage_Ende_01052021/Cologne_tonalities_v2.scd");
	//
	// MIDIClient.init;
	// MIDIIn.connectAll;


/*	5.0.wait;*/


~nyquist = s.sampleRate * 0.5;




~fftbuffers = Array.fill(2,{Buffer.alloc(s, 1024,1)});


~bike0smpls = Array.fill(2, { Buffer.alloc(s, 3.0 * s.sampleRate, 1); });
~bike1smpls = Array.fill(2, { Buffer.alloc(s, 3.0 * s.sampleRate, 1); });

//~samplePath2 = "/media/numina/DATAPANIC/Dropbox/Samples/AnsageEnde/".asString;
//~testSample = Buffer.read(s, ~samplePath2++"/Gamelan/Slentem/SlentemPl1.wav" );
~win1 = Buffer.sendCollection(s, Signal.hammingWindow(1024));

~samNum1 = 0;
~samNum2 = 0;

~fbrecBufs = Array.fill(2, { Array.fill(2, { Buffer.alloc(s, s.sampleRate * 10, 1); }); });
~recrecBufs = Array.fill(2, { Buffer.alloc(s, s.sampleRate * 10, 1); });

//samples

//~frogs_long = Buffer.read(s, (~samplePath2++"/boerderij/kikkers/lang/kikkers_lang_1.wav"));
//~bijen = Buffer.read(s, (~samplePath2++"/boerderij/bijen/bijen_01.wav") );

~firstgeneration_grainsample1 =  {  ~bike0smpls[~samNum1];      };
~firstgeneration_grainsample2 = 	 { ~bike1smpls[~samNum2] ;      };


3.0.wait;
//groups
~synthGroup2 = Group.tail(~synthGroup);
~gerriGroup = Group.new(~synthGroup2);
~noteGroups2 = Array.fill(8, { Group.new(~gerriGroup); });


~recGroup = Group.after(~synthGroup2);
//groups for sample loopers
~playGroups = Array.fill(2, { Array.fill(2, { Group.head(~synthGroup2); }); });
~recGroups = Array.fill(2, {|i| Array.fill(2, {|j| Group.after(~playGroups[i][j]); }); });
//sampler groups
//group for resample grain loop
~recrecGroups = Array.fill(2, {|i| Group.after(~synthGroup2); });
~compressGroup = Group.after(~gerriGroup);

~sidechainBus = Bus.audio(s, 2);
~controlBus = Bus.audio(s, 2);
~snareverbBus = Bus.audio(s, 2);
~compressBus = Bus.audio(s, 2);

/*
~sideChainer.free;
~sideChainer.set(\ratio, 0.8);*/
~sideChainer = Synth(\sidechainer, [\inBus, ~sidechainBus, \controlBus, ~controlBus, \thresh, 0.1, \ratio,0.8,\volume,1.0], ~compressGroup);

//~drumcompressor.set(\ratio,0.1);

//buses for record sample loop
~vectorBuses = Array.fill(2, { Array.fill(2, { Bus.audio(s, 1); }); });

//compress buses
~compressBuses = Array.fill(8, {
	Array.fill(4, {
		Bus.audio(s, 1);}); });
~recrecbus = Array.fill(2, { Array.fill(2, { Bus.audio(s, 1); }); });

//control buses
~lengthBuses = Array.fill(4, { Array.fill(10, {Bus.control(s, 1).set(0.1)}); });
~startBuses = Array.fill(2, { Array.fill(2, { Bus.control(s, 1).set(0.0); }); });

~ampBuses = Array.fill(8, { Bus.control(s, 1).set(0.25); });

~ampBus = Array.fill(2, {  Bus.control(s,1).set(0.001); });

~endBus = [
			Bus.control(s, 1).set(~bike0smpls[~samNum1].numFrames),
			Bus.control(s, 1).set(~bike1smpls[~samNum2].numFrames) ];

~endRecBus = Array.fill(2, {|i| Bus.control(s, 1).set(~recrecBufs[i].numFrames); });

~recordBuf = Buffer.alloc(s, 1024,1);

//specs
~lengthSpec = [1.0,0.001,\exp].asSpec;
//~lengthSpec = [0.001, 1.0,\linear].asSpec;
//~endSpec = [0.001, 1.0,\linear].asSpec;
~endSpec = [1.0,0.0001,\exp].asSpec;
~clockSpec = [0.5, 3.0, \exp].asSpec;
~startSpec = [0.0,0.9,\linear].asSpec;
~vecFreqSpec = [1, 19000,\exp].asSpec;
~octaveSpec = [0,6,\linear,1,1].asSpec;
~radioplayAmpSpec = [0.5,0.1,\linear].asSpec;
//differentiate length specs
~lengthSpecs = Array.fill(10, {|i| [0.75-((i+1)/20.408163265306),0.001,\linear].asSpec; });

~chooseBus = Bus.control(s, 1).set(1);

~whatFirstGrainSample = [0,0];
~whatSecondGrainSample = [0,0];


//tempo clocks for grain patterns
~clocks = Array.fill(4, { TempoClock.new; });
~recordClock = TempoClock.new(1);
//sample buffers

//arrays for buttons / switches
~startValues = [[0.0, 0.0],[0.0,0.0]];
~reverseButtons = [[0,0],[0,0]];
~playButtons  = [[0,0],[0,0]];
~recButtons  = [[0,0],[0,0]];
~starts  = [[0,0],[0,0]];
~playSwitches = [[0,0],[0,0]];
~recSwitches = [[0,0],[0,0]];
~sampleLengths = [[1.0,1.0],[1.0,1.0]];
~octave = [[1,1],[1,1]];
~octaves = [0.0625,0.125,0.25,0.5,1,2,4];
~radioplayAmps = [[0.1,0.1],[0.1,0.1]];
//feedback gates for rec loops
~fbgates = [0,0];

//array for routine names
~routineNames = Array.fill(2,{|j| Array.fill(2, {|i| "~routineName"++j++i; }); });
~timeRoutineNames = Array.fill(2,{|j| Array.fill(2, {|i| "~timeRoutineName"++j++i; }); });


~sine = Env.sine.discretize(1024).putLast(0);
~sineEnv = Buffer.sendCollection(s, ~sine, 1);

Pbindef(\radioplaypattern).fadeTime = 0.0001;

~inSelector1 = 0;
~inSelector2 = 0;
~selectInputs = [0,0];

~drumLengthSelect = 0;
~drumSamSelect = 0;
~drumPitchSelect = 0;

	//[num,val].postln;


//Server.default.makeGui
// loop different parts in buffer
//~playGroups[0][0].set(\trig, 1);
//get start values
2.do{|i|
2.do{|j|
Routine({inf.do{
~startBuses[i][j].get({|val| ~startValues[i].put(j, (val / s.sampleRate)); });
0.01.wait; } }).play; }; };

/*
~outputs = [ [ ~compressBuses[4][0].index, ~compressBuses[5][0].index ],
	[ ~compressBuses[6][0].index, ~compressBuses[7][0].index] ];
*/


//routines for sample looping without clicks and recording
2.do{|i|

2.do{|j|
var reverse = 1, timeRoutine,timeRoutineSwitch=0,time=0.25, start=0;

Routine({
			inf.do{ var playTime = ~sampleLengths[i][j] * s.sampleRate;

//switch on&off loops - routine speed is based on length sample
if ( ~playButtons[i][j] == 1, { if ( ~playSwitches[i][j] == 0, {
		~playSwitches[i].put(j,1); "playing".postln;
		~routineNames[i][j] = Routine({ inf.do{


if ( ~octave[i][j] > 1,  { if ( ~sampleLengths[i][j] < 0.5, { ~sampleLengths[i].put(j, ~sampleLengths[i][j]*2); });
							//"tooooooo short!!!!".postln;
						});
~startBuses[i][j].get({|item| start = item; });
if ( ~octave[i][j] == 4, { if ( start > ((~sampleLengths[i][j]*s.sampleRate)-start), { start = start - ((~sampleLengths[i][j]*s.sampleRate)-start)}); });

//("start : "++start).postln;
if ( start == inf, { start = ~sampleLengths[i][j]*s.sampleRate*0.5;
"inf error".postln; });
time = (~sampleLengths[i][j] - ~startValues[i][j]) * (1/~octave[i][j]);
time = time + (time*0.05);

if ( time < 0.001, { time = 0.01});

if ( time < 0.01, { if ( start < ((~sampleLengths[i][j]*s.sampleRate)*0.8), {
							start = (~sampleLengths[i][j]*s.sampleRate)*0.8;

							 "damn".postln; }); });


								Synth(\radioplay, [\out,if ( i == 0, { ~sidechainBus }, { ~sidechainBus }); ,\amp,~radioplayAmps[i][j],\nyquist, ~nyquist,\sampleRate, s.sampleRate,
									\mainvolBus, if ( i == 0, { if ( j == 0, { ~ampBuses[2].index }, { ~ampBuses[3].index }); },
										{ if ( j == 0, { ~ampBuses[6].index }, { ~ampBuses[7].index }); }); ,
									\start,start,\bufnum, ~fbrecBufs[i][j], \end, ~sampleLengths[i][j]*s.sampleRate,\reverse,reverse,\xpan,j-1.0,\ypan,j-1.0,\octave, ~octave[i][j],
							\vectorOut,~recrecbus[i][j] ],~playGroups[i][j]);

					time.wait; } });
					~routineNames[i][j].play;
				}) },
					{ if ( ~playSwitches[i][j] == 1,
						{ ~playSwitches[i].put(j,0); ~routineNames[i][j].stop; }); });
if ( ~recButtons[i][j] == 1, {
			if ( ~recSwitches[i][j] == 0,{ ~recSwitches[i].put(j, 1);
				"recording".postln;
						Synth(\radiorecorder,[\in,~vectorBuses[i][j], \bufnum, ~fbrecBufs[i][j]],~recGroups[i][j]);
						if ( ~playSwitches[i][j] == 1, {
							~playGroups[i][j].set(\end,~sampleLengths[i][j]*s.sampleRate); ~playGroups[i][j].set(\trig, 1); });

//routine for measuring the length of recording
~timeRoutineNames[i][j] = Routine({
				inf.do{
				10000.do{|k| if ( k != 0 , {
					if ( ~recSwitches[i][j] == 0, {
					~sampleLengths[i].put(j, k * 0.001);
~playGroups[i][j].set(\start,~starts[i][j]*(~sampleLengths[i][j]*s.sampleRate),\end, ~sampleLengths[i][j]*s.sampleRate);  ~timeRoutineNames[i][j].stop;
						"stopped time routine".postln;

						}); });  0.001.wait; } } }).play;
					}); }, { if ( ~recSwitches[i][j] == 1, { ~recSwitches[i].put(j, 0);
						"sample length : ".postln; ~sampleLengths[i][j].postln;
						~startBuses[i][j].set((~starts[i][j]*~sampleLengths[i][j]*s.sampleRate).postln);
/*
~playGroups[j].set(\start,~starts[j]*(~sampleLengths[j]*s.sampleRate),\end, ~sampleLengths[j]*s.sampleRate);
*/
						~recGroups[i][j].freeAll;
						  }); });
				if ( ~reverseButtons[i][j] == 1, { if ( reverse == 1, {
					reverse = -1; if ( ~playSwitches[i][j] == 1, { ~playGroups[i][j].set(\reverse, reverse); }); }); },
			{ if ( reverse == -1, { reverse = 1;
						if ( ~playSwitches[i][j] == 1, { ~playGroups[i][j].set(\reverse, reverse); }); }); });

		0.01.wait;
	};
}).play;
	};
};
(
//clocks for speed recordings tasks
~recclockSpec = [1.0, 40.0, \exp].asSpec;

~recClocks = Array.fill(2, { TempoClock.new(8); });


(
MIDIdef.cc(\blackcontroller, {|val num chan src|
	[num,val,chan, src].postln;

	//record live audio input for first grain pattern
	case { num == 8 } {

	if ( ~fbgates[0] == 0, {

	if ( val == 127, {

							if ( ~inSelector1 != 5, { "rec direct input 0".postln;

							~recsynth1 = Synth(\zitarRecorder, [\in,~selectInputs[0],\recbuf, ~bike0smpls[~samNum1],\fftbuf, ~fftbuffers[0], \onsetBus, ~onset_bus ], ~recGroup);


							}, { "rec electronics".postln;
							~recsynth1 = Synth(\busRecorder,[\in, ~anaBus,\recbuf, ~bike0smpls[~samNum1],\fftbuf, ~fftbuffers[0] ],~recGroup); });

							}, { ~recsynth1.free; });
					}, {
	if ( val == 127, {

		"recording grain sample 0".postln;
						Synth(\recrecorder,[\in, ~recrecbus[1][0],\chooseBus,~chooseBus.index,
								\bufnum, ~bike0smpls[~samNum1] ],~recrecGroups[1]); });
					});

					}
//select input
	{ num == 16 }
				{ if ( ~inSelector1 != 3,
					{ ~inSelector1 = ~inSelector1 + 1; }, { ~inSelector1 = 0; });
					case
					{ ~inSelector1 == 0 } { "input 0".postln; ~selectInputs.put(0, 0);
						//~firstgeneration_grainsample1 = {   ~bike0smpls[~samNum1];    };

						}
					{ ~inSelector1 == 1 } { "sdr samples".postln; ~selectInputs.put(0, 4);
							//~firstgeneration_grainsample1 =  { ~sdr_samples[1]; };

						}
					{ ~inSelector1 == 2 } { "input recorder flute".postln; ~selectInputs.put(0, 3);
							//~firstgeneration_grainsample1 =   { ~bike0smpls[~samNum1]; };
						}
						{ ~inSelector1 == 3 } { "web sdr input".postln; ~selectInputs.put(0, 6);
							//~firstgeneration_grainsample1 =   { ~bike0smpls[~samNum1]; };
						};


	}


	//record live audio input for second grain pattern
	{ num == 9 } {
	if ( ~fbgates[1] == 0, {

	if ( val == 127 , {


	if ( ~inSelector2 != 5, { "rec direct input 1".postln;
	~recsynth2 = Synth(\zitarRecorder, [\in,~selectInputs[1],\recbuf, ~bike1smpls[~samNum2],\fftbuf, ~fftbuffers[0]], ~recGroup);
								},
			{ "rec electronics".postln;
							~recsynth2 = Synth(\busRecorder,[\in, ~anaBus,\recbuf, ~bike1smpls[~samNum2],\fftbuf, ~fftbuffers[0] ],~recGroup); });



						}, { ~recsynth2.free; }); }, {
	if ( val == 127, {
							"recording grain sample 1".postln;
							Synth(\recrecorder,[\in, ~recrecbus[1][1],
								\bufnum, ~bike1smpls[~samNum2] ],~recrecGroups[1]); });
				}); }
		// select input
		{ num == 17 }
				{ if ( ~inSelector2 != 3, { ~inSelector2 = ~inSelector2 + 1; }, { ~inSelector2 = 0; });
					case
					{ ~inSelector2 == 0 } { "input 0".postln; ~selectInputs.put(1, 0);
						//~firstgeneration_grainsample2 = {   ~bike1smpls[~samNum2];    };
					}
					{ ~inSelector2 == 1 } { "input sdr ".postln; ~selectInputs.put(1, 4);
								//~firstgeneration_grainsample2 = { ~sdr_samples[1]; };

							}
					{ ~inSelector2 == 2 } { "input recorder flute".postln; ~selectInputs.put(1, 3);
								//~firstgeneration_grainsample2 = {   ~bike1smpls[~samNum2];    };
							}
							{ ~inSelector2 == 3 } { "web sdr input".postln; ~selectInputs.put(1, 6);
								//~firstgeneration_grainsample2 = {   ~bike1smpls[~samNum2];    };
							};
	}




	//start&stop pattern 1
	{ num == 24 } {
	"playing pattern 1".postln;

	if ( val == 127, {
10.do{|i|var pan = ((i+1)*0.1)-1,dur = 0.1 + (i*0.01);
Pbindef(("grainpattern1"++i).asSymbol,\instrument, \radioplaypattern,
\group,~synthGroup2, \out,~sidechainBus,
\nyquist, ~nyquist,
\octave, 1,
\t_trig, 1,
\start,0,\endBus,~endBus[0].index,
\lengthBus, ~lengthBuses[0][i].index,\dur,dur,\reverse,Pwrand([1,-1],[0.6,0.4],inf),
\bufnum,
Pfunc({ ~firstgeneration_grainsample1.value}),
\envbuf, ~sineEnv,\ampBus,~ampBuses[0].index,\pan,Pwhite(pan,pan+0.1),
\vectorOut, ~vectorBuses[0][0] ).play(~clocks[0]);
};	},{ 10.do{|i| Pbindef(("grainpattern1"++i).asSymbol).pause; }; }); }
	//change speed + length grains
	{ num == 32 }
	{ ~clocks[0].tempo = ~clockSpec.map(val/127).postln;
		10.do{|i| ~lengthBuses[0][i].set(~lengthSpec.map(val/127);); } }
	//end position in sample
	{ num == 0 }
	{ ~endBus[0].set(~lengthSpec.map(val/127)*(~firstgeneration_grainsample1.value).numFrames); }
//start&stop pattern 2
{ num == 25 } { if ( val == 127, {
5.do{|i|var pan = (i+1)*0.1,dur = 0.1 + (i*0.01);
Pbindef(("grainpattern2"++i).asSymbol,\instrument, \radioplaypattern,\group,~synthGroup2,
\out,~sidechainBus,
\nyquist, ~nyquist,
\octave, 1,
\t_trig, 1,
\start,0,
\endBus,~endBus[1].index,
\lengthBus, ~lengthBuses[1][i].index,
\dur,dur,\reverse,Pwrand([1,-1],[0.6,0.4],inf),
							\bufnum,Pfunc({~firstgeneration_grainsample2.value}),
							\envbuf, ~sineEnv,
							\ampBus,~ampBuses[1].index,
\vectorOut, ~vectorBuses[0][1] ).play(~clocks[1]); } },
		{ 10.do{|i| Pbindef(("grainpattern2"++i).asSymbol).pause; }; }); }
	//change speed + length grains
	{ num == 33 }
	{ ~clocks[1].tempo = ~clockSpec.map(val/127).postln;
		10.do{|i| ~lengthBuses[1][i].set( ~lengthSpec.map(val/127).postln; ); }; }
	//change end position grain pattern
	{ num == 1 }
	{ //~length2 = ~lengthSpec.map(val/127).postln;
		~endBus[1].set(~lengthSpec.map(val/127)*(~firstgeneration_grainsample2.value).numFrames);
	}
	//3rd granular pattern samples the sampler
	//start&stop pattern
	{ num == 28 } { if ( val == 127, {
"pattern3 started".postln;
5.do{|i|var pan = ((i+1)*0.19)-1;
Pbindef(("grainpattern3"++i).asSymbol,\instrument, \regranulate,
\group,~synthGroup2,
\nyquist, ~nyquist,
\ampBus,~ampBuses[4].index,
\out, ~sidechainBus,
\octave, 1,
\start,0,
\endBus,~endRecBus[0].index,
\lengthBus, ~lengthBuses[2][i].index,
\dur,0.1,
\reverse,Pwrand([1,-1],[0.6,0.4],inf),
\bufnum,~recrecBufs[0],\envbuf, ~sineEnv,\pan,Pwhite(pan,pan+0.1),
				\recOut, ~vectorBuses[1][0] ).play(~clocks[2]);
};	},
	{ 10.do{|i| Pbindef(("grainpattern3"++i).asSymbol).stop;};	"pattern 3 stopped".postln; }); }
	{ num == 36 }
	{
		~clocks[2].tempo = ~clockSpec.map(val/127).postln;
		10.do{|i| ~lengthBuses[2][i].set(~lengthSpecs[i].map(val/127);); }
	}
	{ num == 4 }
	{ ~endRecBus[0].set( ((~lengthSpec.map(val/127))*~recrecBufs[0].numFrames).postln;); }

{ num == 20 }
	{ if ( val == 127, { ~durVar3 = Routine({ inf.do{ 100.do{|i| var dur = ~clocks[2].tempo.reciprocal*0.5, time = 0.001 + rrand(0.0001,0.001);
		10.do{|i|
			~lengthBuses[2][i].set(rrand(dur*0.001,dur)); }; time.wait; } }}).play; "dur routine playing".postln; },
		{ ~durVar3.stop; "dur routine stop".postln; });
	}

{ num == 29 } { if ( val == 127, {
"pattern4 started".postln;
5.do{|i|var pan = ((i+1)*0.19)-1,dur = 0.1 + (i*0.001);
Pbindef(("grainpattern4"++i).asSymbol,
\instrument, \regranulate,
\group,~synthGroup2,
\nyquist, ~nyquist,
\ampBus,~ampBuses[5].index,
\out, ~sidechainBus,
\octave, 1,
\start,0,
\endBus,~endRecBus[1].index,
\lengthBus, ~lengthBuses[3][i].index,
\dur,0.1,
\reverse,Pwrand([1,-1],[0.6,0.4],inf),
\bufnum,~recrecBufs[1],\envbuf, ~sineEnv,
				\recOut, ~vectorBuses[1][1]).play(~clocks[3]);
};	},
		{ 10.do{|i| Pbindef(("grainpattern4"++i).asSymbol).stop;};	"pattern 4 stopped".postln; }); }
{ num == 37 }
{
		~clocks[3].tempo = ~clockSpec.map(val/127).postln;
		10.do{|i| ~lengthBuses[2][i].set(~lengthSpecs[i].map(val/127);); }
}
{ num == 5 }
{
		~endRecBus[1].set( ((~lengthSpec.map(val/127))*~recrecBufs[1].numFrames).postln;);
}

{ num == 21 }
	{ if ( val == 127, { ~durVar = Routine({ inf.do{ 100.do{|i| var dur = ~clocks[3].tempo.reciprocal*0.5, time = 0.001 + rrand(0.0001,0.001);
		10.do{|i|
			~lengthBuses[3][i].set(rrand(dur*0.001,dur)); }; time.wait; } }}).play; "dur routine playing".postln; },
		{ ~durVar4.stop; "dur routine stop".postln; });
	}
	//record sampler for grain pattern 3
	{ num == 12 } { "rec 1".postln;
		Synth(\recrecorder,[\in, ~recrecbus[0][0], \bufnum, ~recrecBufs[0]],~recrecGroups[0]); }
	//record sampler for grain pattern 4
	{ num == 13 } { "rec 1".postln;
		Synth(\recrecorder,[\in, ~recrecbus[0][1], \bufnum, ~recrecBufs[1]],~recrecGroups[1]); };





if ( num == 10,
		{  if ( val == 127, {"sampling grain pattern 1".postln;~recButtons[0].put(0,1); },{ ~recButtons[0].put(0,0); }); });
	//play sample
	if ( num == 18,
		{ if ( val == 127, { "playing grain loop 1".postln;~playButtons[0].put(0,1); },{ "stopped grain loop 1".postln; ~playButtons[0].put(0,0); }); });
	//reversed on / off
	if ( num == 26,
		{ if ( val == 127, { "reverse on".postln; ~reverseButtons[0].put(0,1) }, { "reverse off".postln; ~reverseButtons[0].put(0,0) }); });
	//set start position
	if ( num == 34, { ~starts[0].put(0, ~startSpec.map(val/127); ); ~starts[0][0].postln;
		~startBuses[0][0].set(~starts[0][0]*~sampleLengths[0][0]*s.sampleRate);
		~radioplayAmps[0].put(0, ~radioplayAmpSpec.map(val/127); ); ~radioplayAmps[0][0].postln;
	});
	//octave shifting
	if ( num == 2, {
		~octave[0].put(0, ~octaves[~octaveSpec.map(val/127)];); ~octave[0][0].postln;
		if ( ~playSwitches[0][0] == 1, {
			~playGroups[0][0].set(\octave, ~octave[0][0]); }); });
	//record sample 2 from grain pattern 2
	if ( num == 11, {
		if ( val == 127, { "sampling grain pattern 2".postln; ~recButtons[0].put(1,1); },{ ~recButtons[0].put(1,0); });});
	if ( num == 19, { if ( val == 127, { "playing grain loop 2".postln; ~playButtons[0].put(1,1); }, { ~playButtons[0].put(1,0); });});
	//reversed on /off
	if ( num == 27,
	{ if ( val == 127, { "reverse on".postln; ~reverseButtons[0].put(1,1); },{ "reverse off".postln; ~reverseButtons[0].put(1, 0); });});
	//set start position
	if ( num == 35, {
	~starts[0].put(1, ~startSpec.map(val/127) ); ~starts[0][1].postln;
	~startBuses[0][1].set(~starts[0][1]*~sampleLengths[0][1]*s.sampleRate);
	~radioplayAmps[0].put(1, ~radioplayAmpSpec.map(val/127); ); ~radioplayAmps[0][1].postln;
	});
	//octave shifting
	if ( num == 3, {
		~octave[0].put(1, ~octaves[~octaveSpec.map(val/127)]); ~octave[0][1].postln;
		if ( ~playSwitches[0][1] == 1, {
			~playGroups[0][1].set(\octave, ~octave[0][1]); }); });
	//SECOND
		if ( num == 14,
		{  if ( val == 127, {"sampling grain pattern 1".postln;~recButtons[1].put(0,1); },{ ~recButtons[1].put(0,0); }); });
	//play sample
	if ( num == 22,
	{ if ( val == 127, { "playing grain loop 1".postln;~playButtons[1].put(0,1); },{ "stopped grain loop 1".postln; ~playButtons[1].put(0,0); }); });
	//reversed on / off
	if ( num == 30,
	{ if ( val == 127, { "reverse on".postln; ~reverseButtons[1].put(0,1) }, { "reverse off".postln; ~reverseButtons[1].put(0,0) }); });
	//set start position
	if ( num == 38, { ~starts[1].put(0, ~startSpec.map(val/127); ); ~starts[1][0].postln;
		~startBuses[1][0].set(~starts[1][0]*~sampleLengths[1][0]*s.sampleRate);
		~radioplayAmps[1].put(0, ~radioplayAmpSpec.map(val/127); ); ~radioplayAmps[1][0].postln;
	});
	//octave shifting
	if ( num == 6, {
		~octave[1].put(0, ~octaves[~octaveSpec.map(val/127)];); ~octave[1][0].postln;
		if ( ~playSwitches[1][0] == 1, {
			~playGroups[1][0].set(\octave, ~octave[1][0]); }); });
	//record sample 2 from grain pattern 2
	if ( num == 15, {
		if ( val == 127, { "sampling grain pattern 2".postln; ~recButtons[1].put(1,1); },{ ~recButtons[1].put(1,0); });});

	//play sample loop
	if ( num == 23, { if ( val == 127, { "playing grain loop 2".postln; ~playButtons[1].put(1,1); }, { ~playButtons[1].put(1,0); });});
	//reversed on /off
	if ( num == 31,
	{ if ( val == 127, { "reverse on".postln; ~reverseButtons[1].put(1,1); },{ "reverse off".postln; ~reverseButtons[1].put(1, 0); });});
	//set start position
	if ( num == 39, {
		~starts[1].put(1, ~startSpec.map(val/127) ); ~starts[1][1].postln;
		~startBuses[1][1].set(~starts[1][1]*~sampleLengths[1][1]*s.sampleRate);
		~radioplayAmps[1].put(1, ~radioplayAmpSpec.map(val/127); ); ~radioplayAmps[1][1].postln;
	});
	//octave shifting
	if ( num == 7, {
		~octave[1].put(1, ~octaves[~octaveSpec.map(val/127)]); ~octave[1][1].postln;
		if ( ~playSwitches[1][1] == 1, {
			~playGroups[1][1].set(\octave, ~octave[1][1]); }); });
	//rec loops
	if ( num == 100, {
		if ( val == 127, { "rec loop 0 running".postln;
	~recRoutine0 = Routine({
				inf.do{
		"recording sample loop 0".postln;
		~recButtons[0].put(0,1);
		rrand(0.5,2.0).wait;
		"stopped recording sample loop 0".postln;
		~recButtons[0].put(0,0);
		rrand(0.5,2.0).wait;
		"recording grain sample 1".postln;
		Synth(\recrecorder,[\in, ~recrecbus[0][0], \bufnum, ~recrecBufs[0]],~recrecGroups[0]);
		rrand(0.5,2.0).wait;
		"recording sample loop 1".postln;
		~recButtons[1].put(0,1);
		rrand(0.5,2.0).wait;
		"stopped recording sample loop 0".postln;
		~recButtons[1].put(0,0);
		rrand(0.5,2.0).wait;
		if ( ~fbgates[0] == 1, {
		"recording grain sample 0".postln;

						Synth(\recrecorder,[\in, ~recrecbus[1][0],\chooseBus,~chooseBus.index,
							\bufnum, ~bike0smpls[~samNum1] ],~recrecGroups[1]);
						1.0.wait;
						10.do{|i| Pbindef(("grainpattern1"++i).asSymbol,\bufnum,~bike0smpls[~samNum1] ); };
					});
				}
				}).play(~recClocks[0]); }, { "rec loop 0 stopped".postln; ~recButtons[0].put(0,0); ~recButtons[0].put(1,0); ~recRoutine0.stop; }); } );
		if ( num == 101, {
		if ( val == 127, { "rec loop 1 running".postln;
		~recRoutine1 = Routine({
	inf.do{

		~recButtons[0].put(1,1);
		rrand(0.5,2.0).wait;
		~recButtons[0].put(1,0);
		rrand(0.5,2.0).wait;
		Synth(\recrecorder,[\in, ~recrecbus[0][1], \bufnum, ~recrecBufs[1]],~recrecGroups[0]);
		rrand(0.5,2.0).wait;
		~recButtons[1].put(1,1);
		rrand(0.5,2.0).wait;
		~recButtons[1].put(1,0);
		rrand(0.5,2.0).wait;
		if ( ~fbgates[1] == 1, {

		Synth(\recrecorder,[\in, ~recrecbus[1][1],
							\bufnum, ~bike1smpls[~samNum2] ],~recrecGroups[1]);
							1.0.wait;
								10.do{|i| Pbindef(("grainpattern2"++i).asSymbol,\bufnum,~bike1smpls[~samNum2]  ); };
			 });
	}
}).play(~recClocks[1]);
 }, { "rec loop 1 stopped".postln; ~recButtons[1].put(0,0); ~recButtons[1].put(1,0); ~recRoutine1.stop; }); } );
//open close feedback gates
	if ( num == 106, {
		if ( val == 127, {"gate 0 opened".postln; ~fbgates.put(0, 1); },
			{"gate 0 closed".postln; ~fbgates.put(0, 0); }); });
	if ( num == 107, {
		if ( val == 127, {"gate 1 opened".postln; ~fbgates.put(1, 1); },
			{"gate 1 closed".postln; ~fbgates.put(1, 0); }); });


	//second sampler






}, chan: 1);
				);


);













};

);

	~guitarcomb_decaySpec = [0.01, 20.0, 3, 0.001].asSpec;

MIDIdef.cc(\BOSS_footpedal, {| val num chan src|
	[num,val,chan, src].postln;

	case
	{ num == 11 } {
	//granular input

		~granul_group.set(\overlap, ~overlap_spec.map(val/127), \tFreq, ~tfreq_spec.map(val/127); );

	// granular samplers
	if ( ~grain_footswitcher == 0, {
				~endBus[0].set(~lengthSpec.map(val/127)*(~firstgeneration_grainsample1.value).numFrames );

				~synthGroup2.set(\t_trig, 1);


			}, {
			~clocks[0].tempo = ~clockSpec.map(val/127).postln;
		10.do{|i| ~lengthBuses[0][i].set(~lengthSpec.map(val/127);); };
				~synthGroup2.set(\t_trig, 1);

			});

	//buses for lofi sound effects
			~shrateBus.set(~shrate_spec.map(val/127));
			~jitterBus.set(~jitter_spec.map(val/127));

	//guitar comb decay
			~guitarcomb_decayBus.set(~guitarcomb_decaySpec.map(val/127));

		};

},chan: 0);


// loop switching when recording //
~recbuf1_count = 0;
~grainpattern1_checker.stop;
	~grainpattern1_checker = Routine({inf.do{
	~onset_bus.get{|i| //i.postln;
			if ( i!= 0, { "change buffer".postln;
				~synthGroup2.set(\t_trig, 1); });
/*
			if ( ~recbuf1_count == 0, { ~recbuf1_count = ~recbuf1_count + 1; }, { ~recbuf1_count = 0; });
				~recsynth1.set(\recbuf, ~bike0smpls[~recbuf1_count] );*/

		};
		0.01.wait; }; }).play;




/* comb percussion ticks */

MIDIdef.new(\nanoPad, {|val num chan dev|
	var output = ~percBus;
	[val, num, chan, dev].postln;

	/*
	case
		{ val < 63.5 } { output = ~percBus; "perc".postln; }
	{ val >= 63.5 } { output = ~percGrainBus; "grain".postln; };
	*/

	case
	{ num == 36 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127), \phasemIndexBus, ~phasemIndexBus.index, \amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul , \recout, ~anaBus], ~percGroup);
	}
	{ num == 37 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127), \phasemIndexBus, ~phasemIndexBus.index, \amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul , \recout, ~anaBus], ~percGroup);
	}
	{ num == 38 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127), \phasemIndexBus, ~phasemIndexBus.index, \amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul , \recout, ~anaBus ], ~percGroup);
	}
	{ num == 39 } { Synth(\perc, [\out, output,\freq, ~freqRange.map(val/127), \phasemIndexBus, ~phasemIndexBus.index, \amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul , \recout, ~anaBus ], ~percGroup);
	}
	{ num == 40 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127), \phasemIndexBus, ~phasemIndexBus.index, \amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul , \recout, ~anaBus ], ~percGroup);
	}
	{ num == 41 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127), \phasemIndexBus, ~phasemIndexBus.index, \amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul , \recout, ~anaBus ], ~percGroup);
	}
	{ num == 42 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127), \phasemIndexBus, ~phasemIndexBus.index,\amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127)  * ~relMul, \recout, ~anaBus ], ~percGroup);
	}
	{ num == 43 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127), \phasemIndexBus, ~phasemIndexBus.index, \amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127)  * ~relMul, \recout, ~anaBus ], ~percGroup);
	}
	{ num == 44 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127), \phasemIndexBus, ~phasemIndexBus.index, \amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul , \recout, ~anaBus ], ~percGroup);
	}
	{ num == 45 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127),\phasemIndexBus, ~phasemIndexBus.index, \amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul, \recout, ~anaBus  ], ~percGroup);
	}
	{ num == 46 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127),\phasemIndexBus, ~phasemIndexBus.index,\amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127)  * ~relMul, \recout, ~anaBus ], ~percGroup);
	}
	{ num == 47 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127),\phasemIndexBus, ~phasemIndexBus.index, \amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul, \recout, ~anaBus  ], ~percGroup);
	}
	{ num == 48 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127),\phasemIndexBus, ~phasemIndexBus.index, \amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul, \recout, ~anaBus  ], ~percGroup);
	}
	{ num == 49 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127), \phasemIndexBus, ~phasemIndexBus.index, \amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul, \recout, ~anaBus  ], ~percGroup);
	}
	{ num == 50 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127), \phasemIndexBus, ~phasemIndexBus.index,\amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul, \recout, ~anaBus  ], ~percGroup);
	}
	{ num == 51 } { Synth(\perc, [\out, output, \freq, ~freqRange.map(val/127),\phasemIndexBus, ~phasemIndexBus.index,\amp,~ampRange.map(val/127),\release,~releaseRange.map(val/127) * ~relMul, \recout, ~anaBus  ], ~percGroup);
	};

  }, nil, 9, \noteOn, nil);


});

/*
morse frequency with USB
10108.46
10111.18


14073.47

CW
simple morse code
10111.26
10122.97
10123.02

complex morse code
10100.83

aether noise
10136.47

14073.47

*/

