# Narration reference

## Status and scope

**Lee Premium and Karen Premium are the preferred source-voice direction as of 2026-09-21.** The owner reports that both sound substantially closer to a human narrator throughout the closing paragraph. Compact Samantha and Daniel were rejected for their overall artificial delivery, although Daniel improved some problem words. The owner requested comparison of other accents before choosing, and raised a possible voice selector. This is positive short-passage feedback, not a final voice, full-session, or iPhone synthesis acceptance. F remains a preserved historical reference. See the [premium comparison](#premium-voice-direction-and-accent-comparison-2026-09-21).

Natural, human-sounding delivery takes priority over slower syllables. Aim for an audiobook or narrative essay, retaining natural articulation and allowing space between ideas. F established the relaxed pacing direction. The latest feedback permits slightly quicker natural articulation, but speeding Aaron up has not resolved the texture. Preserve restful delivery and compare source voices before further consonant attenuation.

The historical F reference is a 97-word audition, not a complete factual session, an approved distribution asset, or a production playback implementation. [D-007](Decision-Log.md#narration-and-ambience-direction-2026-09-16) remains partly open. [D-001](Decision-Log.md#phase-0-closeout-accepted-decisions-2026-09-15) still selects direct AVSpeechSynthesizer speech for the initial prototype; accepting this processed reference does not select buffered playback.

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

## Word-focused follow-up, 2026-09-17

The owner reports that **H sounds better**, with residual robotic quality in **first, distant, is, nothing, complete, settle, and space**. Preserve that relative improvement and the approved timing; this is not final voice acceptance. Candidate **I** keeps H as its PCM baseline and tests small, local level changes around six of those words. **Complete remains unchanged**: the conservative noise detector finds no qualifying event there. Its reported artifact remains unresolved, and weakening the voiced syllables would not establish a fix.

A diagnostic render using the same whole paragraph, voice, and settings produced a CAF byte-identical to the original (SHA-256 `b2141529606f4e1bb4f9644c5848b0eb7baa3662619c794b03fa96c704f1edd6`). Word metadata offsets reset at an internal chunk; an independently rendered suffix reproduced the original PCM exactly from frame 587,264, establishing that mapping. **These metadata anchors are not acoustic word or phoneme boundaries.** For example, the anchor for “settle” falls after the nearby high-frequency burst. Explicit local neighborhoods and signal inspection guide this audition; phoneme identity and exclusion of neighboring coarticulation are not proven. Diagnostic synthesis supplies location evidence only; it does not replace any sample in I.

Analysis uses a 20 ms Hann window and 5 ms hop on the original gain-adjusted paragraph. Within the selected neighborhoods, candidate frames require a 3,500–11,000 Hz share of at least 0.45 relative to 200–14,000 Hz, a 200–2,500 Hz share below 0.35, RMS above −42 dBFS, and high-band spectral flatness above 0.10. Events must span at least 15 ms. An additional smooth positive gain multiplies H's samples directly, with raised-cosine fades up to 20 ms wholly inside each event. There is no spectral reconstruction, normalization, pitch shift, time stretching, or whole-word attenuation.

| Local neighborhood | Original paragraph time | Selected events | Maximum additional reduction from H |
| --- | --- | --- | --- |
| first | 6.650–7.035 s | 3 | 1 dB |
| distant | 11.670–12.155 s | 3 | 1 dB |
| is | 13.250–13.345 s | 1 | 1.5 dB |
| nothing | 13.540–13.635 s | 1 | 1 dB |
| complete | 17.570–17.845 s inspected | 0 | Unchanged |
| settle | 20.330–20.485 s | 1 | 1 dB |
| space | 22.045–22.445 s | 2 | 1 dB |

These are search neighborhoods, not claims of word onset/end. The dry preview adds 0.25 seconds before this timeline. “Is” receives a slightly larger local adjustment because H's strict low-band guard missed the mixed-noise region there; this still does not identify the cause of its perceived robotic texture.

| Check | I result |
| --- | --- |
| Dry duration / frames | 25.086667 seconds / 1,204,160, identical to H |
| Additional edit support | 11 events / 33,578 frames / 0.699542 seconds |
| Paragraph samples outside new mask | 1,146,582; 97.154793% bit-identical to H |
| Actual changed samples after rounding | 31,744 |
| Paragraph RMS, H / I | −22.943690 / −22.947053 dBFS |
| Peak / clipping | −5.443772 dBFS / none |
| Preserved properties | Exact sample positions, original zeros, lead/tail silence, polarity, and all samples outside new mask |
| Rain transition | 40.086667 seconds; all 732,000 frames after the paragraph identical to H |

The local dry file is `I-Word-focused-gentle-transitions.wav` (SHA-256 `c0679e136a7e939124ffbc3196d47d81614a52536dc0dffd42050f0747a18fa4`). The transition file is `I-Narration-to-rain.wav` (SHA-256 `98329295151c2fcd509766004317af341938971ffa70fc63b668d0db527d37d4`). The local manifest retains the exact regions, gain settings, source fingerprints, and corrected marker evidence. These artifacts and diagnostic scripts remain outside the repository.

I initially required listening feedback; the owner subsequently reported the robotic quality remained noticeable, as recorded below. Level reduction changes prominence, not the source synthesis itself; measurements cannot prove naturalness or unchanged perceived emphasis. If the remaining texture persists, evaluate source delivery rather than indefinitely reducing consonants. Original F, G/H, the full-session master, catalog estimate/text, rain, app code, and D-001's runtime choice remain unchanged. No new app tests or build are needed for this documentation-only repository change; direct audio checks and repository checks cover this iteration.

## Source-voice investigation, 2026-09-20

### What the owner heard

I did not resolve the reported synthetic texture. The owner then compared fresh, unprocessed renders of the same closing paragraph at Aaron rates `0.45` and `0.50`. Both remained robotic; the faster one was slightly better. The faster file sounded identical in the Codex Mac preview and QuickTime. The owner subsequently heard roughly the same robotic quality from both WAVs on iPhone, using AirPods Pro 2. Other audio on those headphones was reported to sound normal.

This makes a Codex-specific or Mac-only playback defect less likely and supports investigating the source voice. It does not identify Aaron's synthesis architecture, prove the exact cause, or exclude every device/headphone contribution. Playing Mac-generated WAVs on iPhone does not test AVSpeechSynthesizer or voice availability in the iPhone app.

### Unprocessed rate controls

Both controls use the unchanged whole closing paragraph (index 12, revision 1 of `turning-fuel-into-motion`), pitch multiplier 1 and utterance volume 1. They apply only constant −4.06 dB gain, signed 16-bit PCM conversion, and 0.25 seconds of silence at each end. There is no de-essing, time stretching, internal pause insertion, or rain.

| Mobile filename | API rate | Raw speech / padded duration | WAV SHA-256 |
| --- | --- | --- | --- |
| `Honkshool-01-Current-Pace.wav` | 0.45 | 24.586667 / 25.086667 s | `938c744909f0fc022c7b744ffa6a0a02632ba3fa91e24f7ff2e340083f290657` |
| `Honkshool-02-Slightly-Faster.wav` | 0.50 | 23.253333 / 23.753333 s | `a2ea703d2215b3fa857f895e91396bd39f5504d33b999f9a2691a2cc8a264278` |

The measured rate increase over this passage is 5.73%; the API settings do not imply a linear percentage change. Independent structural checks found valid WAV lengths, no clipping, and exact agreement with the raw PCM plus gain/padding. I adds no new exact-zero samples relative to its unprocessed source. These checks found no added digital dropout evidence; they do not prove perceptual smoothness.

The exact two files were copied to the owner's iCloud Drive with explicit authorization, verified byte-identical, and confirmed uploaded. The owner could then listen on iPhone. Local-path previews and attempted inline audio cards had not appeared in Codex Mobile. This is a development-file delivery method, not an app cloud-sync feature.

### Installed source-voice comparison

An interpreted Swift inventory on the Mac found 47 English entries. Aaron is the only enhanced English voice family available: `com.apple.siri.natural.Aaron` and `com.apple.ttsbundle.gryphon-neural_Aaron_en-US_premium` both report Voice 1, en-US, quality 2. The second identifier is not evidence of a distinct voice or premium API quality. Alex is absent. No additional voice was downloaded.

The next diagnostic candidates are **Samantha** (`com.apple.voice.compact.en-US.Samantha`) and **Daniel** (`com.apple.voice.compact.en-GB.Daniel`), both API quality 1. They provide distinct voices, with an accent change for Daniel, but are not assumed naturalness upgrades. A quality enum cannot establish the owner's listening preference. Their complete-paragraph renders use rate 0.50, pitch 1, volume 1, and an explicit false assistive-technology-settings preference. Equal numeric rates do not guarantee equal durations or cadence across voices.

| Candidate | Raw / padded duration | Padded frames | Constant gain | Peak dBFS | WAV SHA-256 |
| --- | --- | --- | --- | --- | --- |
| `Honkshool-03-Samantha.wav` | 23.241995 / 23.742041 s | 523,512 | −7.099787 dB | −7.649085 | `a08bc0f0db0a33d817f3dc8276b0b9b233ba3ba95b979f466b76c73270ad48e7` |
| `Honkshool-04-Daniel.wav` | 24.364444 / 24.864490 s | 548,262 | −3.500004 dB | −4.352476 | `e12cbe9c3fc703df3aa863d130ef1f6c86b07646c3bf8a9d29710b8e193728f1` |

Both WAVs preserve the native mono 22,050 Hz sample rate, with signed 16-bit PCM conversion and 5,513 silence frames at each end (0.250023 seconds, the nearest frame to 0.25 seconds). A single constant gain matches each whole-file RMS to the faster Aaron control, approximately −22.882914 dBFS, without compression or local gain changes. There is no filtering, de-essing, resampling, internal pause editing, time stretching, or rain. RMS matching reduces an overall level confound but does not establish equal perceived loudness. Each voice retains its native timing; Samantha's raw duration is close to Aaron's 23.253333 seconds, while Daniel is 1.111111 seconds longer.

The text SHA-256 is `b8a4430c440833cb4b7175a6647e0c96a059cc13bf11ac9ccce12f941f18cd4e`. Raw CAF fingerprints are `daf0417f6476d1cae5d0fd01338ee057abea46f8c3093ad34bf09dbaa8ad4e5a` (Samantha) and `02ff212dcb93265a4b1a869b74971301ac86d98ca5a3bd7f3622f11acff67edd` (Daniel). The local render/export manifests and scratch tools preserve the exact procedure outside Git. Rendering uses the established completion callback, nonzero PCM, and quiet-period guard before sealing each file. Independent CAF/WAV parsing confirms exact frame counts, hashes, and sample-for-sample reconstruction from each source plus its constant gain and padding; neither candidate clips. RMS differs from the Aaron control by less than 0.000001 dB. Original F and the full-session master retain their recorded hashes. Listening must determine whether either changes the distracting texture. No candidate has replaced original F, the full-session master, catalog estimate, or app runtime.

## Premium voice direction and accent comparison, 2026-09-21

### Listening outcome

The owner reports that compact Daniel is less processed around the problem words but that both compact Daniel and Samantha sound more robotic and artificial throughout the whole sample. Neither is a replacement for the earlier reference. Subsequent **Lee Premium** and **Karen Premium** samples sound substantially closer to a human narrator throughout the passage. This shifts the preferred development direction from further processing of Aaron toward verified premium source voices.

Both premium samples use the same original closing paragraph and text hash recorded above, utterance rate 0.50, pitch 1, volume 1, and `prefersAssistiveTechnologySettings = false`. Each whole paragraph is synthesized once with an exact identifier and an explicit API quality-3 requirement; missing voices fail rather than silently falling back. No de-essing, spectral processing, time stretching, internal pause insertion, or rain is applied. A single constant gain matches whole-file RMS to the faster Aaron control, approximately −22.882914 dBFS. RMS matching does not guarantee equal perceived loudness.

| Voice | Exact identifier | Locale | Raw / padded duration | WAV SHA-256 |
| --- | --- | --- | --- | --- |
| Lee Premium | `com.apple.voice.premium.en-AU.Lee` | en-AU | 23.317007 / 23.817052 s | `3581d60e28300bf5384b4d4d75a045fefa59b7cdc3ccc84972d1497c401cd950` |
| Karen Premium | `com.apple.voice.premium.en-AU.Karen` | en-AU | 23.491293 / 23.991338 s | `cefd98c118fc98824a5051e20bd6b6ee6c12f0718a199b3a714fb683b477c5f1` |

Local files `Honkshool-05-Lee-Premium.wav` and `Honkshool-06-Karen-Premium.wav` retain native mono 22,050 Hz audio, converted to signed 16-bit PCM with 5,513 silence frames at each end. Their frame counts are 525,166 and 529,009. Constant gains are −5.901224 and −6.060416 dB respectively; sample peaks are −8.668379 and −9.821749 dBFS. Separate standard-library CAF/WAV parsing and exact sample reconstruction passed, with no clipping and less than 0.000002 dB RMS difference from the reference. Original F and the full-session master retain their fingerprints. The local manifests and scratch tools preserve the procedure outside Git.

### Next accent comparison

The owner requested different accents before settling on a voice. Premium is an [Apple quality category](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoicequality/premium), not evidence that all voices have the same articulation, phrasing, pronunciation, or duration. Compare American and British premium candidates with the already preferred Australian reference using the unchanged paragraph, natural timing, and matched overall level. The owner downloaded Ava Premium (American) and Jamie Premium (British), and both now resolve as API quality 3 on the Mac. Their availability on the target iPhone must be checked separately.

The earlier picker attempt downloaded Lee/Karen Premium and basic Jamie instead of the initially targeted Ava/Jamie Premium. The original system voice was restored to Samantha and verified. A later attempt isolated individual premium entries, but downloads did not become available through automation; the owner was asked to initiate the two downloads manually. The owner then completed both requested downloads, resolving that blocker. No basic voice is substituted into the accent comparison. The owner is now listening in desktop Codex, so the earlier pending iCloud transfer is no longer needed.

### Completed accent auditions

The same whole closing paragraph now has two additional local auditions. They use rate 0.50, pitch 1, volume 1, and an explicit false assistive-technology preference, with exactly resolved quality-3 voices. Jamie is the API's display name, while its stable identifier contains `Malcolm`; these names refer to the same resolved premium asset and are not guessed substitutions.

| Voice | Exact identifier | Locale | Raw / padded duration | Padded frames | WAV SHA-256 |
| --- | --- | --- | --- | --- | --- |
| Ava Premium | `com.apple.voice.premium.en-US.Ava` | en-US | 24.023673 / 24.523719 s | 540,748 | `e08ffced2d9d974b908930690b7e8d9a7dd1c5602367f7a2379b0f85b315845d` |
| Jamie Premium | `com.apple.voice.premium.en-GB.Malcolm` | en-GB | 23.676644 / 24.176689 s | 533,096 | `8dc493cac126c0413683c1e4b1f64b7cf72385b68e0993f0dc112e3a19bc5704` |

The files are `Honkshool-07-Ava-Premium.wav` and `Honkshool-08-Jamie-Premium.wav`. Both retain native mono 22,050 Hz audio and use the same 16-bit conversion and 5,513-frame end padding as Lee/Karen. Their constant gains are −5.538628 and −5.702682 dB; sample peaks are −8.221305 and −6.529867 dBFS. Raw CAF fingerprints are `a3f1a347a9a63ea14e81643e596791836e7e7ae2e34d4b820d4873b2d50aae07` (Ava) and `cf8227a808e4da0ed64f4fd36896fd34015386d3d653b7f034764940235c1196` (Jamie).

Separate standard-library CAF/WAV parsing verifies catalog text identity, format/frame counts, hashes, exact PCM reconstruction from constant gain plus padding, no clipping, and RMS within 0.000001 dB of the same Aaron level reference. Lee/Karen, F, and the full-session master retain their prior hashes. Whole-paragraph completion uses the established delegate/nonzero-PCM/quiet-period guards. No system voice setting was changed for these renders, and no iCloud transfer was needed.

These samples preserve each voice's native cadence; no duration matching or time stretching is applied. All four premium auditions last approximately 24 seconds at the same API rate, but similar duration does not establish identical phrasing or naturalness. Ava/Jamie listening feedback is pending. No voice has been chosen as the default, no full-session estimate has been changed, and no selector is implemented.

### Proposed selector boundary

A selector is technically feasible: the current feasibility controller already assigns an `AVSpeechSynthesisVoice`, although it currently resolves by language rather than a saved exact voice identity. The owner's suggestion was conditional on premium voices behaving alike, which these two positive samples do not establish. Compare accents first; no selector or production runtime change is implemented by this audition.

For a subsequent product implementation, a small curated selector should show voice name/accent and a preview, distinguish installed voices from unavailable downloads, and save the listener's choice. Resolve and validate the exact voice before starting. A different voice can change narration duration, so regenerate and review the Nap Plan using an estimate measured for the selected voice/settings; retain D-004's fixed deadline. Freeze voice/settings for the active run and apply changes to a later plan, with no mid-nap prompt or silent lower-quality substitution. Actual completion and revision-specific partial progress remain authoritative.

Short Mac auditions do not establish target-iPhone voice availability, technical pronunciation, or full-session comfort. A replacement requires a complete timing measurement before replacing the configured 675-second estimate. Direct speech remains the accepted initial runtime strategy under D-001. The exported Mac WAVs remain personal test artifacts; public distribution of recordings needs a separate review of applicable voice-license terms, rather than inferring redistribution rights from a free download.

## Remaining validation

1. Compare premium English accents against the preferred Lee/Karen direction at an ordinary comfortable volume. Assess whole-passage naturalness, clarity, and comfort before choosing a default or implementing a curated selector. F remains a historical provisional reference.
2. Enumerate voices available to the target iPhone app and verify supported direct-speech delivery against this reference. Do not silently substitute a lower-quality voice or assume that the Mac identifier is usable on iPhone.
3. Check pronunciation of the prepared script's technical terms, naturalness over a full session, and duration on the intended iPhone playback path. A full Mac measurement is now recorded, but does not replace that check. Keep duration estimates configurable; the fixed wake deadline remains governed by D-004.
4. Validate a proposed production voice with a short comparison against the preferred premium samples before adoption. If direct speech cannot meet the accepted sound, record the evidence and make an explicit runtime decision before adopting a different strategy.
5. Audition the prepared CC0 gentle-rain candidate under D-008, then check the combination with narration, drift, and silence. F's voice-only approval does not establish a rain mix or asset license.
