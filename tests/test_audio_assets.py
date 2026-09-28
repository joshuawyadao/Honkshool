from __future__ import annotations

import array
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest
import wave


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = PROJECT_ROOT / "scripts/prepare-rain.py"
NARRATION_SCRIPT = PROJECT_ROOT / "scripts/prepare-kokoro-narration.py"
RESOURCES = PROJECT_ROOT / "Honkshool/Resources"
spec = importlib.util.spec_from_file_location("prepare_rain", SCRIPT)
prepare_rain = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare_rain)


def rms(samples):
    return math.sqrt(sum(sample * sample for sample in samples) / len(samples))


class PreparedRainTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.provenance = json.loads(
            (RESOURCES / "GentleRain-Provenance.json").read_text(encoding="utf-8")
        )
        cls.asset = RESOURCES / "GentleRain.wav"
        with wave.open(str(cls.asset), "rb") as audio:
            cls.parameters = audio.getparams()
            pcm = array.array("h", audio.readframes(audio.getnframes()))
        if sys.byteorder != "little":
            pcm.byteswap()
        cls.pcm = pcm
        cls.samples = [sample / 32768 for sample in pcm]

    def test_shipped_audio_matches_provenance_fingerprint(self):
        self.assertEqual(self.provenance["fileName"], self.asset.name)
        self.assertEqual(
            hashlib.sha256(self.asset.read_bytes()).hexdigest(),
            self.provenance["preparedSHA256"],
        )
        self.assertEqual(self.provenance["originalSHA256"], prepare_rain.SOURCE_SHA256)
        self.assertEqual(
            self.asset.stat().st_size, self.provenance["validation"]["fileBytes"]
        )

    def test_shipped_pcm_metadata_matches_provenance(self):
        measured = self.provenance["validation"]
        self.assertEqual(self.parameters.comptype, "NONE")
        self.assertEqual(self.parameters.nchannels, measured["channelCount"])
        self.assertEqual(self.parameters.sampwidth * 8, measured["bitsPerSample"])
        self.assertEqual(self.parameters.framerate, measured["sampleRate"])
        self.assertEqual(self.parameters.nframes, measured["frameCount"])
        self.assertEqual(len(self.pcm), self.parameters.nframes)
        self.assertAlmostEqual(
            self.parameters.nframes / self.parameters.framerate,
            measured["durationSeconds"],
        )

    def test_shipped_levels_are_quiet_and_unclipped(self):
        measured = self.provenance["validation"]
        rms_db = 20 * math.log10(rms(self.samples))
        peak_db = 20 * math.log10(max(abs(sample) for sample in self.samples))
        clipped = sum(sample in (-32768, 32767) for sample in self.pcm)
        self.assertAlmostEqual(rms_db, measured["rmsDBFS"], places=6)
        self.assertAlmostEqual(peak_db, measured["peakDBFS"], places=6)
        self.assertEqual(clipped, measured["clippedSamples"])
        self.assertEqual(clipped, 0)
        self.assertAlmostEqual(rms_db, -33, delta=0.1)
        self.assertLessEqual(peak_db, -15)

    def test_loop_wrap_is_smaller_than_internal_sample_steps(self):
        seam = abs(self.samples[-1] - self.samples[0])
        maximum_step = max(
            abs(after - before)
            for before, after in zip(self.samples, self.samples[1:])
        )
        self.assertLess(seam, maximum_step)
        self.assertAlmostEqual(seam, self.provenance["validation"]["loopSeamStep"])
        self.assertAlmostEqual(
            maximum_step, self.provenance["validation"]["maximumAdjacentStep"]
        )

    def test_preparation_is_deterministic_and_removes_one_second(self):
        rate = 16000
        generator = random.Random(27)
        source = [generator.uniform(-0.5, 0.5) for _ in range(4 * rate)]
        first = prepare_rain.prepare(source, rate)
        second = prepare_rain.prepare(source, rate)
        self.assertEqual(first, second)
        self.assertEqual(len(first), len(source) - rate)
        self.assertGreater(rms(first), 0)
        self.assertLess(max(abs(sample) for sample in first), 32767)

    def test_preparation_rejects_silent_or_short_input(self):
        for source in ([0.0] * 48000, [0.25] * 47999, []):
            with self.subTest(length=len(source)), self.assertRaises(ValueError):
                prepare_rain.prepare(source, 16000)

    def test_preparation_rejects_nonfinite_or_out_of_range_pcm(self):
        for invalid in (float("nan"), float("inf"), float("-inf"), 1.01, -1.01):
            source = [0.1] * 48000
            source[len(source) // 2] = invalid
            with self.subTest(value=invalid), self.assertRaises(ValueError):
                prepare_rain.prepare(source, 16000)

    def test_highpass_removes_dc_and_preserves_audible_signal(self):
        rate = 16000
        source = [
            0.3 + 0.2 * math.sin(2 * math.pi * 500 * index / rate)
            for index in range(3 * rate)
        ]
        filtered = prepare_rain.filter_loop(source, rate, 100, highpass=True)
        self.assertEqual(len(filtered), len(source))
        self.assertAlmostEqual(sum(filtered) / len(filtered), 0, delta=1e-8)
        self.assertGreater(rms(filtered), 0.1)
        self.assertLess(rms(filtered), 0.15)

    def test_cli_refuses_wrong_source_without_creating_output(self):
        with tempfile.TemporaryDirectory() as directory:
            source, output = Path(directory) / "source.wav", Path(directory) / "out.wav"
            source.write_bytes(b"a different recording")
            result = subprocess.run(
                [sys.executable, str(SCRIPT), str(source), str(output)],
                capture_output=True, text=True, check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Source fingerprint differs", result.stderr)
            self.assertFalse(output.exists())

    def test_cli_preserves_existing_output(self):
        with tempfile.TemporaryDirectory() as directory:
            source, output = Path(directory) / "source.wav", Path(directory) / "out.wav"
            source.write_bytes(b"source must remain untouched")
            output.write_bytes(b"existing audio must remain untouched")
            result = subprocess.run(
                [sys.executable, str(SCRIPT), str(source), str(output)],
                capture_output=True, text=True, check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Output already exists", result.stderr)
            self.assertEqual(output.read_bytes(), b"existing audio must remain untouched")
            self.assertEqual(source.read_bytes(), b"source must remain untouched")


class NarrationPublicationGuardTests(unittest.TestCase):
    def run_renderer(self, *arguments):
        with tempfile.TemporaryDirectory() as cache_root:
            return subprocess.run(
                [sys.executable, str(NARRATION_SCRIPT), "--cache-root", cache_root,
                 *map(str, arguments)],
                capture_output=True, text=True, check=False,
            )

    def test_default_invocation_preserves_original_wav_and_provenance(self):
        wav = RESOURCES / "Turning-Fuel-Into-Motion-George.wav"
        provenance = RESOURCES / "GeorgeNarration-Provenance.json"
        before = (hashlib.sha256(wav.read_bytes()).digest(), provenance.read_bytes())
        result = self.run_renderer()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Output already exists", result.stderr)
        self.assertEqual(hashlib.sha256(wav.read_bytes()).digest(), before[0])
        self.assertEqual(provenance.read_bytes(), before[1])

    def test_existing_destinations_and_symlinks_fail_before_model_imports(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            catalog = RESOURCES / "PreparedCatalog.json"
            for occupied in ("output", "provenance"):
                for symlink in (False, True):
                    with self.subTest(occupied=occupied, symlink=symlink):
                        marker = root / "marker"
                        marker.write_bytes(b"untouched")
                        destination = root / occupied
                        if symlink:
                            destination.symlink_to(marker)
                        else:
                            destination.write_bytes(b"untouched")
                        output = destination if occupied == "output" else root / "new.wav"
                        provenance = destination if occupied == "provenance" else root / "new.json"
                        result = self.run_renderer("--catalog", catalog, "--output", output,
                                                   "--provenance", provenance)
                        self.assertNotEqual(result.returncode, 0)
                        self.assertIn("already exists", result.stderr)
                        self.assertEqual(marker.read_bytes(), b"untouched")
                        self.assertEqual(destination.read_bytes(), b"untouched")
                        destination.unlink()

    def test_overlapping_destinations_and_catalog_fail_early(self):
        catalog = RESOURCES / "PreparedCatalog.json"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for output, provenance in (
                (root / "same", root / "same"),
                (catalog, root / "new.json"),
                (root / "new.wav", catalog),
            ):
                with self.subTest(output=output, provenance=provenance):
                    result = self.run_renderer("--catalog", catalog, "--output", output,
                                               "--provenance", provenance)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("paths overlap", result.stderr)


class PreparedNarrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        catalog = json.loads(
            (RESOURCES / "PreparedCatalog.json").read_text(encoding="utf-8")
        )
        cls.sessions = {session["id"]: session for session in catalog["sessions"]}
        cls.provenance_files = {
            "turning-fuel-into-motion": "GeorgeNarration-Provenance.json",
            "air-fuel-and-spark": "Air-Fuel-and-Spark-George-Provenance.json",
        }
        cls.assets = {}
        for session_id, filename in cls.provenance_files.items():
            provenance = json.loads((RESOURCES / filename).read_text(encoding="utf-8"))
            asset = RESOURCES / provenance["outputFile"]
            with wave.open(str(asset), "rb") as audio:
                parameters = audio.getparams()
                pcm_bytes = audio.readframes(audio.getnframes())
            pcm = array.array("h", pcm_bytes)
            if sys.byteorder != "little":
                pcm.byteswap()
            cls.assets[session_id] = (cls.sessions[session_id], provenance, asset,
                                      parameters, pcm_bytes, pcm)

    def test_every_catalog_narration_has_a_checked_asset(self):
        catalog_assets = {
            session_id for session_id, session in self.sessions.items()
            if "narrationAsset" in session
        }
        self.assertEqual(catalog_assets, set(self.assets))
        shipped_george = {path.name for path in RESOURCES.glob("*-George.wav")}
        self.assertEqual(shipped_george, {item[2].name for item in self.assets.values()})

    def test_original_narration_fingerprint_and_revision_remain_fixed(self):
        session, provenance, asset, *_ = self.assets["turning-fuel-into-motion"]
        self.assertEqual(session["revision"], "1")
        self.assertEqual(provenance["sessionRevision"], "1")
        self.assertEqual(provenance["narrationTextSHA256"],
                         "7e44406d9d07d90463ffcceb977be64cbb43cbd6fe50524e769b3ce34af56f52")
        self.assertEqual(asset.name, "Turning-Fuel-Into-Motion-George.wav")
        self.assertEqual(provenance["outputSHA256"],
                         "7117b18ce10e45844b6eba29936370131290baf30131b71cf2b01d5999847f37")

    def test_second_session_identity_and_revision_are_fixed(self):
        session, provenance, asset, *_ = self.assets["air-fuel-and-spark"]
        self.assertEqual(session["revision"], "1")
        self.assertEqual(provenance["sessionID"], "air-fuel-and-spark")
        self.assertEqual(provenance["sessionRevision"], "1")
        self.assertEqual(asset.name, "Air-Fuel-and-Spark-George.wav")

    def test_catalog_points_to_the_verified_bundled_asset(self):
        for session_id, (session, provenance, asset, *_rest) in self.assets.items():
            with self.subTest(session=session_id):
                metadata = session["narrationAsset"]
                self.assertEqual(provenance["sessionID"], session_id)
                self.assertEqual(asset.name, f'{metadata["resource"]}.{metadata["fileExtension"]}')
                self.assertEqual(metadata["sha256"], provenance["outputSHA256"])
                self.assertEqual(hashlib.sha256(asset.read_bytes()).hexdigest(), metadata["sha256"])
                self.assertEqual(asset.stat().st_size, provenance["outputBytes"])
                self.assertEqual(metadata["duration"], provenance["durationSeconds"])
                self.assertEqual(session["estimatedDuration"],
                                 math.ceil(metadata["duration"] / 5) * 5)

    def test_provenance_matches_the_current_versioned_script(self):
        for session_id, (session, provenance, *_rest) in self.assets.items():
            with self.subTest(session=session_id):
                narration = "\n\n".join(paragraph["text"] for paragraph in session["paragraphs"])
                self.assertEqual(provenance["sessionRevision"], session["revision"])
                self.assertEqual(provenance["narrationTextSHA256"],
                                 hashlib.sha256(narration.encode("utf-8")).hexdigest())
                self.assertEqual(provenance["paragraphCount"], len(session["paragraphs"]))
                self.assertEqual(len(provenance["paragraphs"]), len(session["paragraphs"]))
                self.assertEqual(provenance["wordCount"],
                                 sum(len(item["text"].split()) for item in session["paragraphs"]))
                for index, (source, prepared) in enumerate(zip(session["paragraphs"], provenance["paragraphs"])):
                    self.assertEqual(prepared["index"], index)
                    self.assertEqual(prepared["textSHA256"],
                                     hashlib.sha256(source["text"].encode("utf-8")).hexdigest())
                    self.assertTrue(prepared["chunks"])
                    self.assertEqual(prepared["frames"], sum(chunk["frames"] for chunk in prepared["chunks"]))
                    self.assertTrue(all(chunk["frames"] > 0 for chunk in prepared["chunks"]))
                    self.assertTrue(all(chunk["textSHA256"] and chunk["phonemesSHA256"]
                                        for chunk in prepared["chunks"]))

    def test_wav_format_duration_and_levels_match_provenance(self):
        for session_id, (_session, provenance, _asset, parameters, _bytes, pcm) in self.assets.items():
            with self.subTest(session=session_id):
                self.assertEqual(parameters.comptype, "NONE")
                self.assertEqual(parameters.nchannels, provenance["channels"])
                self.assertEqual(parameters.sampwidth, 2)
                self.assertEqual(parameters.framerate, provenance["sampleRate"])
                self.assertEqual(parameters.nframes, provenance["frames"])
                self.assertEqual(len(pcm), parameters.nframes)
                self.assertAlmostEqual(parameters.nframes / parameters.framerate,
                                       provenance["durationSeconds"])
                measured_rms = 20 * math.log10(math.sqrt(
                    sum((sample / 32768) ** 2 for sample in pcm) / len(pcm)))
                measured_peak = 20 * math.log10(max(abs(sample) for sample in pcm) / 32768)
                clipped = sum(sample in (-32768, 32767) for sample in pcm)
                self.assertAlmostEqual(measured_rms, provenance["measuredRMSDBFS"], places=6)
                self.assertAlmostEqual(measured_peak, provenance["measuredPeakDBFS"], places=6)
                self.assertEqual(clipped, provenance["clippedSampleCount"])
                self.assertEqual(clipped, 0)

    def test_timing_is_only_model_audio_and_recorded_silence(self):
        for session_id, (_session, provenance, _asset, _parameters, pcm_bytes, _pcm) in self.assets.items():
            with self.subTest(session=session_id):
                paragraph_frames = sum(item["frames"] for item in provenance["paragraphs"])
                expected = (paragraph_frames + provenance["leadingFrames"]
                            + provenance["trailingFrames"]
                            + provenance["paragraphGapFrames"] * (provenance["paragraphCount"] - 1))
                self.assertEqual(expected, provenance["frames"])
                lead = provenance["leadingFrames"] * 2
                trail = provenance["trailingFrames"] * 2
                self.assertFalse(any(pcm_bytes[:lead]))
                self.assertFalse(any(pcm_bytes[-trail:]))

    def test_pinned_george_model_direction_is_preserved(self):
        for session_id, (_session, provenance, *_rest) in self.assets.items():
            with self.subTest(session=session_id):
                self.assertEqual(provenance["engine"], "Kokoro-82M v1.0")
                self.assertEqual(provenance["modelRepository"], "hexgrad/Kokoro-82M")
                self.assertEqual(provenance["modelRevision"],
                                 "f3ff3571791e39611d31c381e3a41a3af07b4987")
                self.assertEqual(provenance["modelSHA256"],
                                 "496dba118d1a58f5f3db2efc88dbdc216e0483fc89fe6e47ee1f2c53f18ad1e4")
                self.assertEqual(provenance["modelLicense"], "Apache-2.0")
                self.assertEqual(provenance["voice"], "bm_george")
                self.assertEqual(provenance["voiceSHA256"],
                                 "f1bc812213dc59774769e5c80004b13eeb79bd78130b11b2d7f934542dab811b")
                self.assertEqual(provenance["languageCode"], "b")
                self.assertEqual(provenance["speed"], 0.86)
                self.assertEqual(provenance["targetRMSDBFS"], -22.882915)
                self.assertEqual(provenance["peakLimitDBFS"], -3.0)
                self.assertEqual(provenance["sampleFormat"], "signed 16-bit little-endian PCM WAV")
                self.assertIn("No filtering", provenance["processing"])


class NarrationMeasurementTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.measurements = json.loads(
            (PROJECT_ROOT / "docs/Audio-Preparation-Measurements.json").read_text(
                encoding="utf-8"
            )
        )
        cls.renderer = cls.measurements["renderer"]
        catalog = json.loads(
            (RESOURCES / "PreparedCatalog.json").read_text(encoding="utf-8")
        )
        cls.session = next(
            session for session in catalog["sessions"]
            if session["id"] == cls.renderer["sessionID"]
        )

    def test_measurements_identify_the_exact_current_script_revision(self):
        self.assertEqual(self.renderer["revision"], self.session["revision"])
        script = "\n\n".join(item["text"] for item in self.session["paragraphs"])
        self.assertEqual(
            self.renderer["scriptSHA256"], hashlib.sha256(script.encode("utf-8")).hexdigest()
        )
        self.assertEqual(
            self.renderer["scriptUTF16Count"], len(script.encode("utf-16-le")) // 2
        )

    def test_every_measured_paragraph_matches_current_text_and_processed_timing(self):
        paragraphs = self.session["paragraphs"]
        rendered = self.renderer["paragraphs"]
        processed = self.measurements["paragraphValidation"]
        self.assertEqual(len(rendered), len(paragraphs))
        self.assertEqual(len(processed), len(paragraphs))
        for index, (paragraph, raw, result) in enumerate(zip(paragraphs, rendered, processed)):
            with self.subTest(paragraph=index):
                self.assertEqual(raw["index"], index)
                self.assertEqual(result["index"], index)
                self.assertEqual(
                    raw["textSHA256"],
                    hashlib.sha256(paragraph["text"].encode("utf-8")).hexdigest(),
                )
                self.assertEqual(
                    raw["textUTF16Count"], len(paragraph["text"].encode("utf-16-le")) // 2
                )
                self.assertGreater(raw["frameCount"], 0)
                self.assertEqual(raw["sampleRate"], self.measurements["full"]["sampleRate"])
                self.assertAlmostEqual(
                    raw["durationSeconds"], raw["frameCount"] / raw["sampleRate"]
                )
                validation = result["validation"]
                self.assertEqual(validation["frame_count"], raw["frameCount"])
                self.assertEqual(validation["sample_rate"], raw["sampleRate"])
                self.assertEqual(validation["duration_seconds"], raw["durationSeconds"])

    def test_full_timing_contains_all_raw_frames_and_only_recorded_added_pauses(self):
        full = self.measurements["full"]
        paragraphs = self.renderer["paragraphs"]
        raw_frames = sum(paragraph["frameCount"] for paragraph in paragraphs)
        self.assertEqual(
            full["frameCount"],
            raw_frames + round(full["addedPauseSeconds"] * full["sampleRate"]),
        )
        self.assertAlmostEqual(full["durationSeconds"], full["frameCount"] / full["sampleRate"])
        self.assertAlmostEqual(
            full["durationSeconds"],
            sum(paragraph["durationSeconds"] for paragraph in paragraphs) + full["addedPauseSeconds"],
        )
        spans = full["paragraphSpans"]
        self.assertEqual(len(spans), len(paragraphs))
        previous_end = pause_frames = 0
        for index, (span, paragraph) in enumerate(zip(spans, paragraphs)):
            with self.subTest(paragraph=index):
                self.assertEqual(span["paragraphIndex"], index)
                self.assertGreaterEqual(span["startFrame"], previous_end)
                self.assertEqual(span["endFrame"] - span["startFrame"], paragraph["frameCount"])
                self.assertLessEqual(span["endFrame"], full["frameCount"])
                pause_frames += span["startFrame"] - previous_end
                previous_end = span["endFrame"]
        pause_frames += full["frameCount"] - previous_end
        self.assertAlmostEqual(pause_frames / full["sampleRate"], full["addedPauseSeconds"])

    def test_historical_aaron_estimate_remains_internally_consistent(self):
        full = self.measurements["full"]
        self.assertEqual(full["configuredEstimateSeconds"], 675)
        self.assertEqual(
            full["configuredEstimateSeconds"], math.ceil(full["durationSeconds"] / 5) * 5
        )


if __name__ == "__main__":
    unittest.main()
