(
// 1. Configurazione Server
s.options.numOutputBusChannels = 2; // Uscita verso le casse reali
s.options.numInputBusChannels = 2;  // Ingresso dal cavo virtuale

// Imposta il nome esatto della periferica (es. "BlackHole 2ch" o "VB-Audio Cable")
// Se non lo conosci, esegui ServerOptions.inDevices per vederli tutti
s.options.inDevice = "VB-Audio Cable";
s.options.outDevice = "NomeDellaTuaSchedaAudioReale"; // Per sentire il risultato

s.boot;
)

(
// 2. Variabili di Stato
~rootFreq = 440;       // Frequenza fondamentale (ricevuta da JUCE)
~complexity = 1;       // Da 1 a 5 (controllata da Joystick asse Y)
~gain = 0.5;           // Volume (controllato da Joystick asse X)
~sourceSelect = 0;     // 0 = Voce, 1 = Chitarra
~activeSynth = nil;    // Per gestire il nodo del sintetizzatore
)


(
SynthDef(\vocalHarmonizer, {
    arg freqs = #[440, 554, 659, 0, 0, 0], // Array di frequenze per l'accordo
    amp = 0.5, gate = 1, vocalIn = 0;

    var sig, modulator, carrier, combined;
    var numBands = 16;
    var bandFreqs = (1..numBands).collect({ |i| i.linexp(1, numBands, 100, 8000) });

    // --- MODULATOR: La tua voce reale dal microfono ---
    modulator = SoundIn.ar(vocalIn);

    // --- CARRIER: Il synth polifonico (Accordo) ---
    // Usiamo Saw per avere molte armoniche da filtrare
    carrier = Mix.ar(Saw.ar(freqs * [1, 1.001], 0.2));

    // --- FILTER BANK (Vocoder Logic) ---
    combined = bandFreqs.collect({ |f|
        var modBand, carBand, env;
        // Analisi della voce: quanto volume c'è in questa frequenza?
        modBand = BPF.ar(modulator, f, 0.1);
        env = Amplitude.kr(modBand, 0.02, 0.05);

        // Sintesi del Carrier: applica l'energia della voce al synth
        carBand = BPF.ar(carrier, f, 0.1);
        carBand * env;
    }).sum;

    // Post-processing
    sig = combined * amp * 5; // Guadagno compensato
    sig = sig * EnvGen.kr(Env.asr(0.1, 1, 0.5), gate, doneAction: 2);

    Out.ar(0, Pan2.ar(sig, 0));
}).add;
)


(
// Funzione per calcolare le note dell'accordo in base alla complessità
~getChordFreqs = { |root, complexity|
    var semitones;
    semitones = switch (complexity.asInteger,
        1, { [0, 7] },             // Quinta (Power chord)
        2, { [0, 4, 7] },          // Triade Maggiore
        3, { [0, 4, 7, 11] },       // Maj7
        4, { [0, 4, 7, 11, 14] },   // Maj9
        5, { [0, 4, 7, 11, 14, 17] },// 13th (Complessità massima)
        { [0, 7] }
    );
    (root.cpsmidi + semitones).midicps.extend(6, 0); // Converte in Hz e riempie l'array a 6
};

// --- RICEVITORI OSC ---

// 1. Pitch dalla Voce (da JUCE)
OSCFunc({ |msg|
    if(~sourceSelect == 0) {
        ~rootFreq = msg[1];
        ~activeSynth.set(\freqs, ~getChordFreqs.(~rootFreq, ~complexity));
    }
}, '/vocalPitch');

// 2. Pitch dalla Chitarra (da JUCE)
OSCFunc({ |msg|
    if(~sourceSelect == 1) {
        ~rootFreq = msg[1];
        ~activeSynth.set(\freqs, ~getChordFreqs.(~rootFreq, ~complexity));
    }
}, '/guitarPitch');

// 3. Selezione Sorgente (On/Off Chitarra)
OSCFunc({ |msg|
    ~sourceSelect = msg[1];
    "Sorgente cambiata a: %".format(if(~sourceSelect==0, {"VOCE"}, {"CHITARRA"})).postln;
}, '/sourceSelect');

// 4. Joystick (Arduino)
OSCFunc({ |msg|
    // asse X (msg[1]) -> Gain (mappato 0-1023 a 0.0-1.0)
    ~gain = msg[1].linlin(0, 1023, 0.0, 1.0).lag(0.1);

    // asse Y (msg[2]) -> Complessità (mappato 0-1023 a 1-5)
    ~complexity = msg[2].linlin(0, 1023, 1, 5).round;

    ~activeSynth.set(\amp, ~gain);
    ~activeSynth.set(\freqs, ~getChordFreqs.(~rootFreq, ~complexity));
}, '/joystick');
)


(
// Inizia a suonare
~activeSynth = Synth(\vocalHarmonizer, [\freqs, ~getChordFreqs.(440, 1), \amp, 0.5]);

// Funzione di test ciclico
Routine({
    loop {
        "Test: Cambio Nota e Complessità".postln;
        ~rootFreq = [440, 329, 349, 392].choose; // Note casuali (La, Mi, Fa, Sol)
        ~complexity = (1..5).choose;

        ~activeSynth.set(\freqs, ~getChordFreqs.(~rootFreq, ~complexity));
        ~activeSynth.set(\amp, 0.4);

        2.wait;
    }
}).play;
)

// Per fermare tutto:
// ~activeSynth.free;