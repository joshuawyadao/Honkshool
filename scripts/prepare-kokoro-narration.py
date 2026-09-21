#!/usr/bin/env python3
"""Prepare one pinned Kokoro catalog session as a verified PCM WAV asset."""

from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
import math
import os
from pathlib import Path
import shutil
import tempfile
import wave


SAMPLE_RATE = 24_000
LEAD_TRAIL_FRAMES = SAMPLE_RATE // 4
PARAGRAPH_GAP_FRAMES = SAMPLE_RATE
TARGET_RMS_DBFS = -22.882915
PEAK_LIMIT_DBFS = -3.0
SEED = 20_260_921


def parse_arguments() -> argparse.Namespace:
  repository = Path(__file__).resolve().parents[1]
  parser = argparse.ArgumentParser()
  parser.add_argument("--cache-root", type=Path, required=True)
  parser.add_argument(
    "--catalog",
    type=Path,
    default=repository / "Honkshool/Resources/PreparedCatalog.json",
  )
  parser.add_argument("--session-id", default="turning-fuel-into-motion")
  parser.add_argument("--voice", default="bm_george")
  parser.add_argument("--language", default="b")
  parser.add_argument("--speed", type=float, default=0.86)
  parser.add_argument(
    "--output",
    type=Path,
    default=repository / "Honkshool/Resources/Turning-Fuel-Into-Motion-George.wav",
  )
  parser.add_argument(
    "--provenance",
    type=Path,
    default=repository / "Honkshool/Resources/GeorgeNarration-Provenance.json",
  )
  return parser.parse_args()


def sha256_bytes(value: bytes) -> str:
  return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
  digest = hashlib.sha256()
  with path.open("rb") as handle:
    for block in iter(lambda: handle.read(1024 * 1024), b""):
      digest.update(block)
  return digest.hexdigest()


def main() -> None:
  arguments = parse_arguments()
  cache_root = arguments.cache_root.resolve()
  os.environ["HF_HOME"] = str(cache_root / "hf-cache")
  os.environ["HF_HUB_OFFLINE"] = "1"
  os.environ["TRANSFORMERS_OFFLINE"] = "1"
  os.environ["HF_HUB_DISABLE_IMPLICIT_TOKEN"] = "1"
  os.environ["HF_HUB_DISABLE_TELEMETRY"] = "1"
  os.environ["HF_HUB_DISABLE_XET"] = "1"
  os.environ["DO_NOT_TRACK"] = "1"

  import espeakng_loader
  import numpy as np
  import torch
  from huggingface_hub import hf_hub_download
  from kokoro import KModel, KPipeline
  from phonemizer.backend.espeak.wrapper import EspeakWrapper

  asset_manifest_path = cache_root / "model-assets.json"
  asset_manifest = json.loads(asset_manifest_path.read_text())
  repository_id = asset_manifest["repo"]
  revision = asset_manifest["revision"]
  expected_assets = {
    item["file"]: item for item in asset_manifest["assets"]
  }
  required_assets = [
    "config.json",
    "kokoro-v1_0.pth",
    f"voices/{arguments.voice}.pt",
  ]
  resolved_assets: dict[str, Path] = {}
  for filename in required_assets:
    path = Path(
      hf_hub_download(
        repo_id=repository_id,
        filename=filename,
        revision=revision,
        token=False,
        local_files_only=True,
      )
    )
    expected = expected_assets[filename]
    if path.stat().st_size != expected["bytes"] or sha256_file(path) != expected["sha256"]:
      raise ValueError(f"Pinned model asset does not match its manifest: {filename}")
    resolved_assets[filename] = path

  catalog = json.loads(arguments.catalog.read_bytes())
  session = next(
    item for item in catalog["sessions"] if item["id"] == arguments.session_id
  )
  paragraphs = [item["text"] for item in session["paragraphs"]]
  if not paragraphs:
    raise ValueError("The selected session has no narration paragraphs.")
  narration = "\n\n".join(paragraphs)

  torch.set_num_threads(2)
  torch.manual_seed(SEED)
  np.random.seed(SEED)

  with tempfile.TemporaryDirectory(prefix="hk-espeak-", dir="/tmp") as temporary:
    shutil.copytree(
      espeakng_loader.get_data_path(), Path(temporary) / "espeak-ng-data"
    )
    EspeakWrapper.set_data_path(temporary)
    model = KModel(
      repo_id=repository_id,
      config=str(resolved_assets["config.json"]),
      model=str(resolved_assets["kokoro-v1_0.pth"]),
    ).to("cpu").eval()
    pipeline = KPipeline(
      lang_code=arguments.language, repo_id=repository_id, model=model
    )
    if pipeline.g2p.fallback is None:
      raise RuntimeError("The British-English phoneme fallback is unavailable.")

    rendered_paragraphs = []
    paragraph_records = []
    for index, paragraph in enumerate(paragraphs):
      _, tokens = pipeline.g2p(paragraph)
      missing = [
        token.text
        for token in tokens
        if any(character.isalnum() for character in token.text)
        and not token.phonemes
      ]
      if missing:
        raise ValueError(f"Unphonemized tokens in paragraph {index + 1}: {missing}")
      chunks = list(
        pipeline(
          paragraph,
          voice=str(resolved_assets[f"voices/{arguments.voice}.pt"]),
          speed=arguments.speed,
          split_pattern=None,
        )
      )
      if not chunks or " ".join(chunk.graphemes for chunk in chunks) != paragraph:
        raise ValueError(f"Kokoro changed paragraph {index + 1} text or chunk order.")
      if any(len(chunk.phonemes) > 510 or chunk.audio is None for chunk in chunks):
        raise ValueError(f"Invalid model chunk in paragraph {index + 1}.")
      audio = np.concatenate(
        [chunk.audio.detach().cpu().numpy() for chunk in chunks]
      ).astype("<f4")
      if audio.ndim != 1 or audio.size <= SAMPLE_RATE or not np.isfinite(audio).all():
        raise ValueError(f"Invalid audio output for paragraph {index + 1}.")
      rendered_paragraphs.append(audio)
      paragraph_records.append(
        {
          "index": index,
          "textSHA256": sha256_bytes(paragraph.encode()),
          "wordCount": len(paragraph.split()),
          "frames": int(audio.size),
          "rawFloat32SHA256": sha256_bytes(audio.tobytes()),
          "chunks": [
            {
              "textSHA256": sha256_bytes(chunk.graphemes.encode()),
              "phonemesSHA256": sha256_bytes(chunk.phonemes.encode()),
              "frames": len(chunk.audio),
            }
            for chunk in chunks
          ],
        }
      )

  assembled = [np.zeros(LEAD_TRAIL_FRAMES, dtype=np.float64)]
  for index, audio in enumerate(rendered_paragraphs):
    assembled.append(audio.astype(np.float64))
    if index < len(rendered_paragraphs) - 1:
      assembled.append(np.zeros(PARAGRAPH_GAP_FRAMES, dtype=np.float64))
  assembled.append(np.zeros(LEAD_TRAIL_FRAMES, dtype=np.float64))
  source = np.concatenate(assembled)
  source_rms = float(np.sqrt(np.mean(source * source)))
  rms_gain = (10 ** (TARGET_RMS_DBFS / 20)) / source_rms
  peak_gain = (10 ** (PEAK_LIMIT_DBFS / 20)) / float(np.max(np.abs(source)))
  gain = min(rms_gain, peak_gain)
  pcm = np.rint(source * gain * 32768).astype("<i2")
  if np.any((pcm == -32768) | (pcm == 32767)):
    raise ValueError("Prepared narration clips at the selected gain.")

  arguments.output.parent.mkdir(parents=True, exist_ok=True)
  with wave.open(str(arguments.output), "wb") as output:
    output.setnchannels(1)
    output.setsampwidth(2)
    output.setframerate(SAMPLE_RATE)
    output.writeframes(pcm.tobytes())

  decoded_pcm = None
  with wave.open(str(arguments.output), "rb") as prepared:
    if (
      prepared.getnchannels() != 1
      or prepared.getsampwidth() != 2
      or prepared.getframerate() != SAMPLE_RATE
      or prepared.getnframes() != len(pcm)
    ):
      raise ValueError("The exported WAV format does not match the prepared PCM.")
    decoded_pcm = prepared.readframes(prepared.getnframes())
  if decoded_pcm != pcm.tobytes():
    raise ValueError("The exported WAV does not preserve the prepared PCM exactly.")

  measured_rms = math.sqrt(
    sum((int(sample) / 32768) ** 2 for sample in pcm) / len(pcm)
  )
  measured_peak = max(abs(int(sample)) for sample in pcm) / 32768
  provenance = {
    "schemaVersion": 1,
    "sessionID": session["id"],
    "sessionRevision": session["revision"],
    "narrationTextSHA256": sha256_bytes(narration.encode()),
    "wordCount": sum(len(paragraph.split()) for paragraph in paragraphs),
    "paragraphCount": len(paragraphs),
    "engine": "Kokoro-82M v1.0",
    "modelRepository": repository_id,
    "modelRevision": revision,
    "modelLicense": "Apache-2.0",
    "modelSHA256": expected_assets["kokoro-v1_0.pth"]["sha256"],
    "voice": arguments.voice,
    "voiceSHA256": expected_assets[f"voices/{arguments.voice}.pt"]["sha256"],
    "languageCode": arguments.language,
    "speed": arguments.speed,
    "seed": SEED,
    "sampleRate": SAMPLE_RATE,
    "channels": 1,
    "sampleFormat": "signed 16-bit little-endian PCM WAV",
    "paragraphGapFrames": PARAGRAPH_GAP_FRAMES,
    "leadingFrames": LEAD_TRAIL_FRAMES,
    "trailingFrames": LEAD_TRAIL_FRAMES,
    "gainLinear": gain,
    "targetRMSDBFS": TARGET_RMS_DBFS,
    "peakLimitDBFS": PEAK_LIMIT_DBFS,
    "peakLimited": peak_gain < rms_gain,
    "outputFile": arguments.output.name,
    "outputSHA256": sha256_file(arguments.output),
    "outputBytes": arguments.output.stat().st_size,
    "frames": len(pcm),
    "durationSeconds": len(pcm) / SAMPLE_RATE,
    "measuredRMSDBFS": 20 * math.log10(measured_rms),
    "measuredPeakDBFS": 20 * math.log10(measured_peak),
    "clippedSampleCount": 0,
    "processing": (
      "Kokoro native duration control; paragraph chunks concatenated in order; "
      "one second of silence between paragraphs; 250 ms at each end; one constant "
      "whole-file gain. No filtering, de-essing, pitch shifting, resampling, "
      "compression, rain, or waveform time stretching."
    ),
    "dependencies": {
      name: importlib.metadata.version(name)
      for name in [
        "kokoro",
        "misaki",
        "torch",
        "transformers",
        "spacy",
        "espeakng-loader",
        "numpy",
      ]
    },
    "assets": [
      {
        "file": filename,
        "sha256": expected_assets[filename]["sha256"],
        "bytes": expected_assets[filename]["bytes"],
      }
      for filename in required_assets
    ],
    "paragraphs": paragraph_records,
  }
  arguments.provenance.write_text(json.dumps(provenance, indent=2) + "\n")
  print(json.dumps({key: provenance[key] for key in [
    "outputFile", "outputSHA256", "outputBytes", "durationSeconds",
    "measuredRMSDBFS", "measuredPeakDBFS", "peakLimited"
  ]}, indent=2))


if __name__ == "__main__":
  main()
