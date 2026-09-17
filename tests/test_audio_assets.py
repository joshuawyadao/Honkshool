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

    def test_planning_estimate_rounds_up_the_complete_measured_duration(self):
        full = self.measurements["full"]
        self.assertEqual(full["configuredEstimateSeconds"], self.session["estimatedDuration"])
        self.assertEqual(self.session["estimatedDuration"], math.ceil(full["durationSeconds"] / 5) * 5)


if __name__ == "__main__":
    unittest.main()
