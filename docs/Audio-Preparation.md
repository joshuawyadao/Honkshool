# Audio preparation

## Status, 2026-09-21

The accepted narration direction is now **Kokoro-82M v1.0 voice `bm_george` at model speed `0.86`**. The owner found both Kokoro Heart and George much more human and natural than the Apple auditions, preferred George's calm documentary character, and selected the more spacious of two native-duration comparisons. See the [accepted Kokoro reference](Narration-Reference.md#accepted-kokoro-george-direction-2026-09-21) for exact assets, settings, samples, fingerprints, and validation.

[Audition F](Narration-Reference.md), the Apple premium comparisons, and the Aaron full-session master remain unchanged historical references. The configurable 675-second estimate still describes that earlier Mac render; the selected Kokoro voice has not yet rendered the complete session. Target-iPhone Kokoro feasibility, full-session pronunciation/timing, rain acceptance, and production integration remain open.

The machine-readable [narration measurements](Audio-Preparation-Measurements.json) preserve the historical Apple work, and [rain provenance](../Honkshool/Resources/GentleRain-Provenance.json) retains the bundled ambience evidence. Kokoro model assets, manifests, scratch tools, full narration audio, and listening previews remain local outside the repository. The rain candidate is [GentleRain.wav](../Honkshool/Resources/GentleRain.wav).

## Accepted Kokoro cadence evidence

The selected comparison uses the unchanged first three paragraphs of **Turning Fuel Into Motion**, totaling 408 words. George at default model speed `1.0` measures 141.000 seconds with the established paragraph gaps and end padding. A gentle `0.92` comparison measures 148.050 seconds. The accepted `0.86` comparison measures 155.975 seconds and has WAV SHA-256 `fa62df1623cf17f6261127cc1d51cbcb055f9fc9e01402b938e14ff2416cafa7`.

Kokoro predicts new phoneme durations for each speed. The accepted output is not a post-render time stretch. Preparation adds one second between the three paragraphs, 0.25 seconds at each end, and one constant gain over the assembled file. It adds no filtering, de-essing, pitch shift, resampling, compression, rain, or word-level edits. Exact catalog text, model revision, model/voice assets, chunk order, PCM construction, output hashes, levels, and absence of clipping passed. The owner's listening establishes the preferred sound; file checks do not independently transcribe the output or prove full-session comfort.

This acceptance does not add Kokoro to the app. A later implementation must first validate an on-device path and decide whether to prepare audio before a nap or synthesize locally during preparation. Either approach must expose a reliable measured duration before Nap Plan approval and remain compatible with D-004's fixed deadline.

## Full narration audition

The audition renders all 13 paragraphs of **Turning Fuel Into Motion**, session `turning-fuel-into-motion`, script revision `1`, from the [prepared catalog](../Honkshool/Resources/PreparedCatalog.json). Paragraph text is unchanged. The complete spoken script has 10,824 UTF-16 code units and SHA-256 `7e44406d9d07d90463ffcceb977be64cbb43cbd6fe50524e769b3ce34af56f52`.

The Mac renderer uses `com.apple.siri.natural.Aaron`, reported as Voice 1 with quality 2, at the reference's base rate `0.45`, pitch multiplier `1`, and utterance volume `1`. Rate `0.45` is an API setting, not words per minute. Each complete paragraph is one utterance so its sentence delivery remains generated in context.

The local audition then applies the reference's constant −4.06 dB gain and the existing E/F processing recipe independently to each paragraph: E supplies spectral softening, while F's narrow mask limits changes to candidate high-frequency bursts. The detector does not identify verified phonemes. **92.67965% of paragraph frames remain bit-identical to the gain-adjusted base outside those regions.** This percentage excludes the silence added between paragraphs and at the ends. The measurement file retains the earlier scripts' C/E comparison field names; for this run, “C” denotes each new paragraph's gain-adjusted base, not the separate 97-word C audition.

Assembly adds one second between each pair of paragraphs, 0.25 seconds at the beginning, and 0.50 seconds at the end: 12.75 seconds in total. It does not transfer C's passage-specific sentence-gap insertions to the new text. No speech is pitch-shifted or time-stretched. The owner subsequently approved the presented tempo and cadence. Sibilance quality and comfort over the full session remain open.

| Property | Recorded value |
| --- | --- |
| Raw paragraph duration | 661.472 seconds |
| Added silence | 12.75 seconds |
| Full processed duration | 674.222 seconds, approximately 11 minutes 14 seconds |
| Configured planning estimate | 675 seconds |
| Encoding | WAV, mono, 48,000 Hz, signed 16-bit PCM |
| Frame count / file size | 32,362,656 frames / 64,725,356 bytes |
| Whole-file RMS / sample peak | −23.281060 / −4.914071 dBFS |
| Candidate regions processed | 671 across 13 paragraphs |
| Unchanged paragraph frames | 29,426,398 of 31,750,656; 92.67965% |
| Clipping / timing | No clipping; every paragraph retains its frame count, with zero measured correlation lag |
| Full-file SHA-256 | `805555e9040a7465c8e48adc7710aa2801343a46257619ef457b434f69407a4e` |
| Opening preview duration | 89.536667 seconds |

The configured estimate replaces the earlier **765-second unmeasured editorial estimate** with this measured Mac audition rounded up to the next five-second increment: `ceil(674.222 / 5) * 5 = 675` seconds. It remains configurable and does not represent measured direct speech on iPhone. Speech output can vary with the installed voice and operating system. Neither an estimate nor the end of an audio file overrides the fixed deadline, actual completion, or resume rules in [D-004](Decision-Log.md#phase-1-timing-resolution-2026-09-15).

### Reproduce the raw paragraph render

Run from the repository root on a Mac with the required voice installed:

```sh
honkshool_audition_dir="$(mktemp -d)"
swift scripts/render-narration.swift \
  Honkshool/Resources/PreparedCatalog.json \
  turning-fuel-into-motion \
  "$honkshool_audition_dir/raw"
```

[render-narration.swift](../scripts/render-narration.swift) uses the system AVFoundation, CryptoKit, and Foundation frameworks. It writes one PCM CAF per complete paragraph and a final `manifest.json` containing text hashes, voice settings, formats, frame counts, and measured durations. The output directory must not exist and its parent must exist. The command refuses a missing required voice instead of selecting a substitute; a failed run may leave partial files without a completed manifest. It neither plays audio nor changes the catalog estimate.

This command reproduces the raw-render procedure. It does not assemble the measured processed audition. That local postprocessing reused the existing audition scripts and already available NumPy outside the app; those scratch scripts and previews are not repository dependencies. The [reference recipe](Narration-Reference.md#focused-sibilant-softening) and measurements document the applied processing. Byte-identical voice synthesis across machines or OS versions is not assumed.

### Local listening previews

Local artifacts include the opening 89.54 seconds, a 40.09-second preview of the complete closing paragraph followed by rain, a 30-second rain-only preview, and a compact 128 kbps AAC copy of the full narration. The compact copy decodes to the same 32,362,656-frame duration without clipping; the WAV fingerprint above identifies the lossless processed master.

The transition preview leaves 0.25 seconds after the closing paragraph, then fades rain in over one second. Rain previews fade out at their end; the bundled looping resource has no end fade. This is an offline audition of the transition, not a production envelope or a background-rain mix. It changes neither the accepted F file nor the runtime.

## Rain candidate and provenance

The source is **Rain on Window Loop** by **alxl**, retrieved on 2026-09-17 from the [creator's OpenGameArt page](https://opengameart.org/content/rain-on-window-loop), with an [original WAV download](https://opengameart.org/sites/default/files/rain_on_window_loop.wav). The page offers several alternative licenses and explicitly states: “Available under CC0; attribution is appreciated but not necessary.” Honkshool selects the **CC0 1.0** option. The [official CC0 terms](https://creativecommons.org/publicdomain/zero/1.0/) allow copying, modification, and distribution, including commercial use. This source record preserves the creator and provenance without implying endorsement.

The original is a short recording described as medium rain against a window. Preparation downmixes it to mono, joins its tail and head with a one-second equal-power crossfade, applies a 100 Hz high-pass and two 3,800 Hz low-pass Butterworth filters, then applies constant gain targeting −33 dBFS RMS with a −15 dBFS sample-peak ceiling. Each filter runs over three loop passes to settle its boundary state. The crossfade reduces the loop length by one second; speech or rain playback speed is not changed. No varying gain envelope or compressor is applied.

| Property | Prepared value |
| --- | --- |
| Duration | 9.866259 seconds |
| Encoding | WAV, mono, 44,100 Hz, signed 16-bit PCM |
| Frame count / file size | 435,102 frames / 870,248 bytes |
| Whole-file RMS / sample peak | −33.000264 / −18.320071 dBFS |
| Approximate half-second RMS range | 1.985587 dB |
| Loop seam sample step | 0.001190185546875 in normalized PCM |
| Largest adjacent sample step | 0.023651123046875 in normalized PCM |
| Clipped samples | 0 |
| Original SHA-256 | `97b9405025e5ed7ed8a58d24dd7146d06e925519b1f718efda94bb85dcd1a61a` |
| Prepared SHA-256 | `060a5183311a297c7370607d50902f054240b280dde54e00a278e90e692438c5` |

These checks describe the file and its boundary, not the perceived absence of a loop, sharp drips, or distracting repetition. Rain level is a candidate asset level, not an accepted narration mix or a listening-volume guarantee.

### Reproduce rain preparation

From the repository root:

```sh
honkshool_rain_dir="$(mktemp -d)"
curl --fail --location \
  https://opengameart.org/sites/default/files/rain_on_window_loop.wav \
  --output "$honkshool_rain_dir/source.wav"
python3 scripts/prepare-rain.py \
  "$honkshool_rain_dir/source.wav" \
  "$honkshool_rain_dir/GentleRain.wav"
```

[prepare-rain.py](../scripts/prepare-rain.py) uses only the Python standard library. It verifies the original source fingerprint and stereo 16-bit 44.1 kHz format before processing, refuses an existing output file, and prints the resulting frame count and hash. No app dependency is added.

## Remaining evidence

1. Validate an on-device Kokoro implementation on the target iPhone, including audio parity, packaging/notices, app/model size, latency, memory, thermals, battery, locked-screen/background behavior, and interruptions.
2. Render and listen to the full session with George at model speed `0.86`; verify technical pronunciation, chunk boundaries, comfort, and measured duration before recalibrating the catalog estimate.
3. Check the rain alone across repeated loop boundaries and alongside selected narration and drift. Accept or revise the short source, filtering, and level based on listening.
4. Connect accepted content and ambience through the future playback adapter, enforcing the fixed deadline and recording actual partial progress and completion. Bundling a candidate does not make it available to the current runtime.

[D-023](Decision-Log.md#kokoro-narration-direction-2026-09-21) selects the preferred narration sound and reopens the production runtime boundary established by D-001. [D-008](Decision-Log.md#audio-preparation-evidence-2026-09-17) remains open, and silence remains the valid fallback.
