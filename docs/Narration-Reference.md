# Narration reference

## Status and scope

**Audition F is the provisional development and listening reference, accepted 2026-09-16.** The owner listened through MacBook speakers and approved continuing development with this sound. Headphone/AirPods listening and target-iPhone playback have not been checked.

Natural, human-sounding delivery takes priority over slower syllables. Aim for an audiobook or narrative essay, retaining natural articulation and allowing space between ideas. Keep the pacing of F. Sibilant softening should reduce sharp “s” sounds without making adjacent syllables sound processed.

This is a 97-word audition, not a complete factual session, an approved distribution asset, or a production playback implementation. [D-007](Decision-Log.md#narration-and-ambience-direction-2026-09-16) remains partly open. [D-001](Decision-Log.md#phase-0-closeout-accepted-decisions-2026-09-15) still selects direct AVSpeechSynthesizer speech for the initial prototype; accepting this processed reference does not select buffered playback.

## Accepted passage

The following original passage was used in A through F:

> Inside a running engine, a piston travels down its cylinder and rises again, returning along the same short path. A connecting rod reaches from the piston to the crankshaft below, joining it at a point set away from the shaft’s center.
>
> As the crankshaft turns, that connection traces a circle, while the piston stays within its straight passage. The rod changes its angle to accommodate both movements, leaning one way and then the other. During the power stroke, expanding gas presses the piston downward, and the rod carries that force to the crankshaft, helping it continue around.

Listening approval does not replace factual review or sourcing. Prepared scripts belong in the [content catalog](Content-Catalog.md) and follow the [content review process](Content-Review.md).

## Voice and pacing origin

The audition was generated offline on a Mac with AVSpeechSynthesizer. The renderer reported **Siri Voice 1 (Aaron)**, identifier `com.apple.siri.natural.Aaron`, with API quality **enhanced (2)**. The successful Mac audition used an interpreted Swift renderer. Availability of that exact voice in the compiled Honkshool iPhone app, and reproduction of the processed reference through direct speech, are not established.

| Setting or step | Recorded value |
| --- | --- |
| Original A utterance rate | `0.45` on the AVSpeechUtterance rate scale; not words per minute |
| Pitch multiplier / utterance volume | `1.0` / `1.0` |
| Original rendered speech duration | 36.16 seconds |
| A gain adjustment | Constant −4.06 dB, targeting −23 dBFS RMS; no time stretching or pitch shift |
| A leading / trailing silence | 0.25 / 0.50 seconds |
| A total duration | 36.91 seconds |
| C and F total duration | 38.86 seconds |
| Ambience in the audition | None |

B used rate `0.30`; the owner found its slower speech more noticeably synthetic. C kept every original A audio sample unchanged and inserted 1.95 seconds of digital silence at existing quiet gaps. F preserves that same timeline. These additions are specific to this audition, rather than universal pause lengths for every sentence:

| After phrase | Insertion frame in A | Time in A | Added pause |
| --- | ---: | ---: | ---: |
| “same short path.” | 391,919 | 8.16498 s | 0.30 s / 14,400 frames |
| “shaft’s center.” (paragraph break) | 743,760 | 15.49500 s | 1.00 s / 48,000 frames |
| “straight passage.” | 1,078,807 | 22.47515 s | 0.25 s / 12,000 frames |
| “then the other.” | 1,356,000 | 28.25000 s | 0.40 s / 19,200 frames |

## Focused sibilant softening

D and E explored stronger de-essing, meaning reduction of sharp high-frequency consonant energy. E improved the “s” sounds, but the owner rejected the effect on surrounding syllables. F restores C's original audio outside short candidate bursts and blends toward E only within those bursts: `F = C + mask × (E − C)`. No speech was regenerated, stretched, pitch-shifted, or normalized in this step.

E supplied up to 6 dB of spectral reduction, detected at 4,500–10,500 Hz, with full-strength gain at 5,500–9,500 Hz and tapered edges at 3,700–11,500 Hz. Its analysis used 2,048-sample windows and 240-sample hops, 3 ms attack, 60 ms release, and 10 ms offline lookahead. F constrains this processed signal to regions selected from C with:

- 20 ms analysis windows and 5 ms hops;
- high-frequency energy at 4,500–11,000 Hz relative to 200–14,000 Hz;
- a seed ratio of at least 0.75 for at least 15 ms and a continuation ratio of at least 0.55;
- an RMS floor above −42 dBFS and less than 0.40 of the measured energy at 200–2,500 Hz;
- 7.5 ms fades inside the selected event, with no pre-roll or release tail into neighboring speech.

These are spectral candidates, not verified phoneme labels. The processing describes how the reference was made; it is not a production DSP requirement or evidence that these settings generalize to another voice or passage.

## Artifact identity and objective checks

The local audition is preserved outside the repository. Binary audio and scratch processing scripts are not bundled with the app. The following fingerprint identifies the exact accepted file without depending on a machine-specific path:

| Property | Value |
| --- | --- |
| Filename | `F-Natural-syllables-focused-softening.wav` |
| SHA-256 | `d570e20f4ad5729bf167b171e6aeac8ad336f96b7b54c78e86e62bbdfdd45fe8` |
| File size | 3,730,604 bytes |
| Encoding | WAV, uncompressed signed 16-bit PCM, mono |
| Sample rate / frame count | 48,000 Hz / 1,865,280 frames |
| Duration | 38.86 seconds |
| Selected candidate regions | 38 |
| Nonzero mask duration | 2.55842 seconds |
| C frames preserved exactly outside events | 1,742,476 frames; 93.416% of the whole file |
| Fully softened event cores | Bit-identical to E |
| Added C pause frames preserved exactly | 93,600 frames / 1.95 seconds |
| Waveform correlation peak lag against C | 0 samples |
| Whole-file RMS, C / F | −23.3130 / −23.3758 dBFS |
| F peak | −5.2918 dBFS |
| High-band energy change in selected cores | −5.4691 dB relative to C |
| Body-band energy change, 100–3,500 Hz | Approximately 0 dB; measured absolute change below 0.01 dB |
| Clipped samples | 0 |
| Export readback | Matches the generated PCM and original format/frame count |

Source fingerprints retained in the audition manifests:

| Source | SHA-256 |
| --- | --- |
| A, natural delivery | `242896e2ce6839d7104ba63bf39d350307a5fbb4dc96d9137ce7b3689c96fe33` |
| C, added pauses | `5e02b597a806071a9b638577523c4d5255169ec8f42850a858c12eb94b61937e` |
| E, broader softening | `1c44d8bf6081199d0f205410d4aa2d6da9a655333ab5f6ba392ed0c5e3b896c9` |

The fingerprint, encoding, frame count, RMS, peak, and absence of clipping were checked against F when this record was written. The event, frequency-band, and waveform-comparison results above come from the recorded audition validation. Signal checks establish file properties and preservation of timing; they do not prove subjective comfort or naturalness.

## Full-session preparation, 2026-09-17

The unchanged revision-1 catalog script has a complete local Mac audition using the same explicit Aaron voice, `0.45` rate, and focused E/F softening approach. It measures **674.222 seconds**; the configurable catalog estimate is **675 seconds**, rounded up to five seconds. Whole paragraphs preserve connected prose, with one added second between paragraphs, 0.25 seconds before speech, and 0.5 seconds after it. The passage-specific sentence-gap insertions in C were not automatically transferred to unrelated sentences.

The original F file is unchanged. This full-session derivative is a new listening candidate, not evidence of identical prosody or owner acceptance. The rain candidate is also prepared, with CC0 provenance and objective signal checks. See [Audio-Preparation.md](Audio-Preparation.md) for commands, measurements, and limitations.

## Sibilance follow-up, 2026-09-17

The owner approved the presented narration's **tempo and cadence**, but reported that the voice still sounded robotic around “s” syllables. Preserve the timing. This is not acceptance of the full voice quality, an assessment of every paragraph, or rain approval.

The earlier full-session processor already reduces selected high-frequency cores by roughly 5 dB. A new short candidate, **G**, tests gentle level reduction on the original gain-adjusted closing paragraph. It avoids frequency-domain reconstruction of the sound. This is a comparison of processing methods, not a diagnosis that filtering caused the reported synthetic quality.

G's detector keeps the same 20 ms analysis window and 5 ms hop, but tightens the seed high-band ratio to 0.80, continuation to 0.65, and maximum low-band share to 0.15. The existing −42 dBFS floor and 15 ms minimum seed remain. Twenty selected regions lie entirely within the prior processor's windows. A smooth positive gain of up to **−3 dB** multiplies the original samples directly, with up to 15 ms raised-cosine fades inside each region and no pre-roll or release into neighboring speech. Analysis uses a spectrum only to choose regions; synthesis, spectral reconstruction, normalization, pitch shift, and time stretching are absent.

| Check | Result |
| --- | --- |
| Paragraph duration / frame count | 24.586667 seconds / 1,180,160 frames |
| Dry preview with original lead/tail | 25.086667 seconds / 1,204,160 frames |
| Format | Mono, 48 kHz, signed 16-bit PCM WAV |
| Selected regions / nonzero gain-mask support | 20 / 1.294167 seconds |
| Original frames outside mask | 1,118,040; 94.736307% bit-identical |
| Flat-core waveform correlation with original | 0.999999965; deviation limited to 16-bit rounding |
| Whole-paragraph RMS, previous / G | −22.953876 / −22.932112 dBFS |
| G sample peak | −5.443772 dBFS; no clipping |
| Timing and zeros | Zero measured lag; all original zero samples and frame positions preserved |
| Transition variant | Same 40.086667-second timeline and byte-identical rain segment |

The local dry files are `Previous-Spectral-softening.wav` and `G-Original-consonant-shape.wav`; the transition file is `G-Narration-to-rain.wav`. G's dry-file SHA-256 is `acf09aa3259754667bb59fd3c6cbc03914d79cf66d9b1ec9adb18c968b61e331`; its transition-file SHA-256 is `1a184a97f2baf071e9ae1951d899b1b3d4173ef98676dc846d2d0fe67eb27cea`. The source paragraph fingerprint is `aeb7ada7361468f2059bdc5048d533e7a51fd6fff19ac678a712e024651fea73`.

The original F file, full-session master, configured 675-second estimate, catalog text, and rain resource remain unchanged. G is a short unaccepted candidate kept outside the repository; it has not been applied across the full session. Detection is not verified phoneme alignment, and local whole-band attenuation can still affect voiced transitions. Signal preservation checks do not prove subjective naturalness. Listening should determine whether the consonant texture improves without losing clarity; continued synthetic quality would warrant evaluating the source voice instead of repeatedly increasing attenuation.

## Continuing the G direction, 2026-09-17

The owner confirmed that **G makes the “s” sounds less robotic while keeping them clear**, but the synthetic character remains noticeable and needs more work. G's level-only method is the preferred direction for further tuning; this is not final voice acceptance. Keep the approved tempo and cadence.

Candidate **H** changes one parameter: the maximum direct sample attenuation increases from 3 to **4.5 dB** on the original PCM. It reuses G's exact 20 regions, detector results, 15 ms maximum inside fades, and zero pre-roll/release. No newly selected region or neighboring sample is touched. In flat event cores, H's amplitude is 84.1395% of G's, a further 1.5 dB reduction. The recorded waveform is retained apart from this smooth gain and integer rounding.

| Check | H result |
| --- | --- |
| Dry duration / frame count | 25.086667 seconds / 1,204,160 frames, equal to G |
| Edited support | Same 1.294167 seconds / 20 regions |
| Samples outside the mask | 94.736307% bit-identical to both G and the original base |
| Paragraph RMS, G / H | −22.932112 / −22.943690 dBFS |
| Peak / clipping | −5.443772 dBFS / none |
| Flat-core correlation with original | 0.999999948 |
| Preserved properties | All original zero samples, word timing, pauses, polarity, and rain-transition timeline |

Local files are `H-Gentler-consonants-same-cadence.wav` (SHA-256 `447d2e723c95a4b383a1818160a54f4bd2841fddf2846e47e4ff9b366cfd134b`) and `H-Narration-to-rain.wav` (SHA-256 `5944202953a19d1d13b6a2e70924f7768516aa291252bc9a2fc9ef1141ada950`). The source and G fingerprints remain those recorded above. H has no amplitude increases relative to G; direct PCM comparison, rather than playback-clock measurement, verifies unchanged sample positions.

H remains a short listening candidate. Reducing prominence can also reduce consonant audibility, so the owner must judge clarity and naturalness together. No claim is made that the synthesis itself has improved. G, the full-session master, the original F file, the 675-second estimate, app code, and rain asset are preserved.

## Remaining validation

1. Compare F on headphones/AirPods at ordinary low listening volume when convenient. MacBook-speaker approval is sufficient to continue current development.
2. Enumerate voices available to the target iPhone app and verify supported direct-speech delivery against this reference. Do not silently substitute a lower-quality voice or assume that the Mac identifier is usable on iPhone.
3. Check pronunciation of the prepared script's technical terms, naturalness over a full session, and duration on the intended iPhone playback path. A full Mac measurement is now recorded, but does not replace that check. Keep duration estimates configurable; the fixed wake deadline remains governed by D-004.
4. Validate any proposed production voice or processing change with a short comparison before treating it as equivalent to F. If direct speech cannot meet the reference, record the evidence and make an explicit runtime decision before adopting a different strategy.
5. Audition the prepared CC0 gentle-rain candidate under D-008, then check the combination with narration, drift, and silence. F's voice-only approval does not establish a rain mix or asset license.
