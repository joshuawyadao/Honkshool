# Audio preparation

## Current status

The accepted narration direction is now **Kokoro-82M v1.0 voice `bm_george` at model speed `0.86`**. The owner found both Kokoro Heart and George much more human and natural than the Apple auditions, preferred George's calm documentary character, and selected the more spacious of two native-duration comparisons. See the [accepted Kokoro reference](Narration-Reference.md#accepted-kokoro-george-direction-2026-09-21) for exact assets, settings, samples, fingerprints, and validation.

[Audition F](Narration-Reference.md), the Apple premium comparisons, and the Aaron full-session master remain unchanged historical references. Two complete Kokoro George sessions are bundled as lossless PCM for production Nap Plans. Turning Fuel Into Motion measures 727.625 seconds (730-second estimate); Air, Fuel, and Spark measures 756.75 seconds (760-second estimate). The feasibility console retains its original first-session example. Production plans also save verified narration checkpoints and partial/completed attempts in local history. The owner selected the unchanged prepared rain candidate for use on 2026-09-28 after receiving a four-loop audition. The production Nap Plan offers it only when the bundled PCM and accepted provenance validate; selected rain loops during rest, with silence as a choice and failure fallback. Target-iPhone rain/route/locked-control checks, relative narration-to-rain level, and full-session subjective comfort remain open.

The machine-readable [narration measurements](Audio-Preparation-Measurements.json) preserve the historical Apple work. [George narration provenance](../Honkshool/Resources/GeorgeNarration-Provenance.json) identifies the original [prepared narration](../Honkshool/Resources/Turning-Fuel-Into-Motion-George.wav); [second-session provenance](../Honkshool/Resources/Air-Fuel-and-Spark-George-Provenance.json) identifies [Air, Fuel, and Spark](../Honkshool/Resources/Air-Fuel-and-Spark-George.wav), and [rain provenance](../Honkshool/Resources/GentleRain-Provenance.json) retains the ambience evidence. Kokoro model weights and the isolated preparation environment remain outside the repository; the app contains the prepared session rather than a model runtime. The rain candidate is [GentleRain.wav](../Honkshool/Resources/GentleRain.wav).

## Accepted Kokoro cadence evidence

The selected comparison uses the unchanged first three paragraphs of **Turning Fuel Into Motion**, totaling 408 words. George at default model speed `1.0` measures 141.000 seconds with the established paragraph gaps and end padding. A gentle `0.92` comparison measures 148.050 seconds. The accepted `0.86` comparison measures 155.975 seconds and has WAV SHA-256 `fa62df1623cf17f6261127cc1d51cbcb055f9fc9e01402b938e14ff2416cafa7`.

Kokoro predicts new phoneme durations for each speed. The accepted output is not a post-render time stretch. Preparation adds one second between the three paragraphs, 0.25 seconds at each end, and one constant gain over the assembled file. It adds no filtering, de-essing, pitch shift, resampling, compression, rain, or word-level edits. Exact catalog text, model revision, model/voice assets, chunk order, PCM construction, output hashes, levels, and absence of clipping passed. The owner's listening establishes the preferred sound; file checks do not independently transcribe the output or prove full-session comfort.

The implementation uses preparation-time synthesis. It does not add Kokoro model weights or an inference dependency to the app. The exact prepared file gives planning a measured duration before approval and lets AVFoundation reproduce the accepted output without a network or metered service.

## Prepared George full session and app asset

All 13 unchanged catalog paragraphs, totaling 1,829 words, were rendered with the pinned Kokoro-82M v1.0 model revision `f3ff3571791e39611d31c381e3a41a3af07b4987`, voice `bm_george`, and native model speed `0.86`. Assembly uses one second between paragraphs, 0.25 seconds at each end, and one constant gain targeting the accepted excerpt's level. It applies no filtering, de-essing, pitch shift, resampling, compression, rain, local word edits, or waveform time stretching.

| Property | Prepared value |
| --- | --- |
| Duration / planning estimate | 727.625 seconds / 730 seconds |
| Encoding | WAV, mono, 24,000 Hz, signed 16-bit PCM |
| Frame count / file size | 17,463,000 frames / 34,926,044 bytes |
| Whole-file RMS / sample peak | −22.882915 / −4.871702 dBFS |
| Full-file SHA-256 | `7117b18ce10e45844b6eba29936370131290baf30131b71cf2b01d5999847f37` |
| Model / voice SHA-256 | `496dba118d1a58f5f3db2efc88dbdc216e0483fc89fe6e47ee1f2c53f18ad1e4` / `f1bc812213dc59774769e5c80004b13eeb79bd78130b11b2d7f934542dab811b` |
| Construction checks | Exact catalog text and chunk order, pinned inputs, exact WAV readback, recorded silence, levels, and zero clipping passed |

The app loads this asset from catalog metadata. A missing or invalid asset visibly fails the run; it never substitutes an Apple voice. AVAudioPlayer supplies prepared-file pause/resume and completion while the existing audio-session, interruption, route-change, remote-command, and ambience path remains in control. A captured deadline task stops prepared narration or subsequent ambience at the planned wake time. Unit tests inject the player and deadline scheduler so deadline, failure, completion, and stale-callback behavior remain deterministic.

Run preparation from the repository root in an isolated environment containing the package versions recorded in the provenance and the pinned Hugging Face cache:

```sh
python3 scripts/prepare-kokoro-narration.py \
  --cache-root /path/to/pinned-kokoro-cache \
  --output outputs/review/Turning-Fuel-Into-Motion-George.wav \
  --provenance outputs/review/GeorgeNarration-Provenance.json
```

The cache root must contain `model-assets.json` and the matching local Hugging Face files. The script operates offline, rejects asset hash or text/chunk mismatches, and writes the WAV plus provenance. Existing destinations and aliases of the catalog or each other are rejected before model imports; final writes use exclusive creation. Use fresh output paths for any review render, then inspect measurements before deliberately publishing a new asset. The pinned model checkpoint is 327,212,226 bytes, while this single lossless prepared session is 34,926,044 bytes. For the curated first prototype, prepared audio therefore avoids a large model and third-party inference runtime while preserving exact sound and duration. The open-source [Kokoro Swift port](https://github.com/mlalma/kokoro-ios) remains relevant if later catalog scale justifies live synthesis; its own documentation requires applications to supply model and voice files.

## Air, Fuel, and Spark — second prepared session

The second session (`air-fuel-and-spark`, revision `1`) contains 1,847 words in 14 paragraphs. It was rendered on 2026-09-28 with the same model revision, verified model/voice hashes, George `bm_george`, British-English pipeline, seed, native speed `0.86`, PCM format, paragraph gaps, end padding, and whole-file level target as the first session. [Content-Review.md](Content-Review.md#air-fuel-and-spark--reviewed-2026-09-28) records the new original script's source review. The original session's text, revision, and complete WAV remain unchanged.

| Property | Prepared value |
| --- | --- |
| Duration / planning estimate | 756.75 seconds / 760 seconds |
| Encoding | WAV, mono, 24,000 Hz, signed 16-bit PCM |
| Frame count / file size | 18,162,000 frames / 36,324,044 bytes |
| Whole-file RMS / sample peak | −22.882915 / −4.826304 dBFS |
| Full-file SHA-256 | `8f8fb647eccb6eec0feeefb20127a681c101ffccb5d94ff9b7b49c95e5cc5fc5` |
| Narration-text SHA-256 | `030b0dee239567c7b45a8eaa755127f7ce210b731f3e9bf23ee491dac429b851` |
| Construction checks | Exact submitted text/chunk order, pinned inputs, complete PCM readback, silence placement, measured levels, and zero clipping passed |

The two WAVs total 71,250,088 bytes (about 68 MiB), excluding rain and metadata. They are bundled content, with no model or inference environment added to the app. A long approved plan can play them in order; finishing the first records completion before starting the second. A stopped or cut-off second session retains its own verified audio position for a fresh plan review. Their combined estimates are 1,490 seconds before settling and drift. Estimates never move the fixed deadline or substitute for completion callbacks.

Reproduction uses an isolated Python 3.11 preparation environment. The prior transient environment was unavailable, so it was recreated from the recorded versions: Kokoro/Misaki `0.9.4`, Torch `2.14.0`, Transformers `4.57.6`, spaCy `3.8.16`, espeakng-loader `0.2.4`, and NumPy `2.4.6`. The English tokenizer package `en-core-web-sm==3.8.0` was installed before rendering and is now also recorded in provenance. Public model assets were downloaded at the pinned revision and checked against the first provenance's byte counts and SHA-256 values before the offline render. No credentials or hosted speech API were used.

The cache-root manifest is a JSON object with `repo`, `revision`, and `assets` (`file`, `sha256`, `bytes` per entry), matching the model fields and assets array in the bundled provenance. Its `hf-cache/` directory holds the matching Hugging Face cache. Install the recorded packages and tokenizer before offline rendering; neither the environment nor the cache belongs in Git. From the repository root, with that environment active:

```sh
python3 scripts/prepare-kokoro-narration.py \
  --cache-root /path/to/pinned-kokoro-cache \
  --session-id air-fuel-and-spark \
  --output outputs/review/Air-Fuel-and-Spark-George.wav \
  --provenance outputs/review/Air-Fuel-and-Spark-George-Provenance.json
```

The provenance records the observed render, not a promise of byte-identical output on every future environment. Complete listening, pronunciation, and relative-level acceptance remain open. Deterministic text and signal checks cannot establish them.

### Short local review reel

For the original Turning Fuel Into Motion session, run `python3 scripts/make-george-review-reel.py` from the repository root to create an ignored 86.125-second WAV in `outputs/`. It copies the first complete synthesis chunk of the opening and middle paragraphs and the complete ending paragraph from the verified bundled file, with the existing one-second paragraph gap between sections. The script checks the source SHA-256 and WAV format; it does not resynthesize, speed up, filter, or change the selected voice. This lets the owner judge representative pronunciation and cadence without sitting through the full session. It cannot prove that every word in the remaining audio is comfortable.

## Historical Aaron full narration audition

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

On 2026-09-28 the owner chose this unchanged candidate after receiving a 39.465-second audition made from four exact repetitions of the bundled PCM, without gain or speed changes. That selection permits `PreparedAmbience` to expose the verified file as Gentle rain in Nap Plan review. The app checks the accepted metadata, expected SHA-256, frame count, and audio format before offering it; the source and selected CC0 license remain recorded in the provenance. This brief audition does not establish the perceived seam over a longer rest, comfortable level relative to the complete George narration, or locked iPhone behavior; those observations remain in the [device checklist](Feasibility-Spike.md#production-gentle-rain-acceptance-on-the-target-iphone).

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

1. The prepared-audio build has installed and launched on the target iPhone; the owner reported locked playback and Lock Screen play/pause working. An opt-in device test passed real AlarmKit alerting and narration cutoff at one shared 75-second deadline on iPhone 18 Pro Max / iOS 27.0, and the owner reported that the alarm rang as expected. Complete the brief Lock Screen Stop, Siri, and AirPods-removal checks in [Feasibility-Spike.md](Feasibility-Spike.md#manual-checks-to-do-later-on-iphone-18-pro-max--ios-270). Locked-screen alarm presentation was not reported.
2. The full bundled file passes identity, timing, and frame-integrity checks. The iOS simulator also reads every frame through AVFoundation and exercises actual AVAudioPlayer tail completion into ambience before an injected fixed cutoff. The owner reported that the opening narration sounded clear and natural during the short device run. The 86-second review reel remains available for representative middle and ending passages; complete-session subjective pronunciation and long-form calmness remain unverified until natural use.
3. The owner selected the existing rain candidate for integration on 2026-09-28. Observe it across repeated loop boundaries on the target iPhone and after narration; record relative level and longer comfort, revising the sound only if listening warrants it.
4. Production Nap Plans and local history are integrated. Complete the physical history/relaunch checks in the device guide; rain must not create narration progress, and the separate feasibility console still does not persist listening history.

[D-023](Decision-Log.md#kokoro-narration-direction-2026-09-21) selects the preferred narration sound. [D-024](Decision-Log.md#prepared-kokoro-playback-2026-09-21) implements it as prepared local audio for the curated prototype while preserving D-001's device evidence. [D-008](Decision-Log.md#open-acceptance-checks) records the selected rain candidate and its remaining device/listening checks; silence remains the default and fallback.
