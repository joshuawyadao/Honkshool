#!/usr/bin/env python3
"""Extract brief, unchanged opening/middle/ending audio for a listening check."""

import argparse
import hashlib
import json
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "Honkshool" / "Resources"
PROVENANCE = RESOURCES / "GeorgeNarration-Provenance.json"
DEFAULT_OUTPUT = ROOT / "outputs" / "George-Opening-Middle-Ending-Review.wav"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    record = json.loads(PROVENANCE.read_text())
    source = RESOURCES / Path(record["outputFile"]).name
    if hashlib.sha256(source.read_bytes()).hexdigest() != record["outputSHA256"]:
        raise ValueError("Bundled George WAV differs from its provenance")

    paragraphs = record["paragraphs"]
    if len(paragraphs) < 3:
        raise ValueError("A review reel needs opening, middle, and ending paragraphs")
    selected = (0, len(paragraphs) // 2, len(paragraphs) - 1)
    gap = record["paragraphGapFrames"]
    sections = []
    for position, index in enumerate(selected):
        paragraph = paragraphs[index]
        length = paragraph["frames"] if position == 2 else paragraph["chunks"][0]["frames"]
        start = record["leadingFrames"] + sum(
            item["frames"] for item in paragraphs[:index]
        ) + gap * index
        sections.append((index, start, length))

    output = args.output.expanduser()
    output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(source), "rb") as original, wave.open(str(output), "wb") as reel:
        if (
            original.getnframes() != record["frames"]
            or original.getframerate() != record["sampleRate"]
            or original.getnchannels() != record["channels"]
            or original.getsampwidth() != 2
        ):
            raise ValueError("Bundled George WAV format differs from its provenance")
        reel.setparams(original.getparams())
        for position, (_, start, length) in enumerate(sections):
            original.setpos(start)
            frames = original.readframes(length)
            if len(frames) != length * original.getnchannels() * original.getsampwidth():
                raise ValueError("Review section extends beyond bundled audio")
            reel.writeframes(frames)
            if position < len(sections) - 1:
                reel.writeframes(bytes(gap * original.getnchannels() * original.getsampwidth()))

    expected_frames = sum(length for _, _, length in sections) + 2 * gap
    with wave.open(str(output), "rb") as reel:
        if reel.getnframes() != expected_frames:
            raise ValueError("Review reel frame count does not match extracted sections")
    print(f"{output}: {expected_frames / record['sampleRate']:.3f} seconds")
    print("Source paragraphs: " + ", ".join(str(index + 1) for index in selected))


if __name__ == "__main__":
    main()
