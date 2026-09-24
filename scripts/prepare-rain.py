#!/usr/bin/env python3
"""Prepare the documented CC0 rain candidate; Python standard library only."""

import argparse
import array
import hashlib
import math
from pathlib import Path
import sys
import wave


SOURCE_SHA256 = "97b9405025e5ed7ed8a58d24dd7146d06e925519b1f718efda94bb85dcd1a61a"


def filter_loop(samples, sample_rate, cutoff, highpass=False):
    """Butterworth biquad, warmed over repeated loops to avoid a filter seam."""
    omega = 2 * math.pi * cutoff / sample_rate
    cosine, sine = math.cos(omega), math.sin(omega)
    alpha = sine / math.sqrt(2)
    a0 = 1 + alpha
    if highpass:
        b0, b1, b2 = (1 + cosine) / 2, -(1 + cosine), (1 + cosine) / 2
    else:
        b0, b1, b2 = (1 - cosine) / 2, 1 - cosine, (1 - cosine) / 2
    b0, b1, b2 = b0 / a0, b1 / a0, b2 / a0
    a1, a2 = -2 * cosine / a0, (1 - alpha) / a0
    x1 = x2 = y1 = y2 = 0.0
    # Each pass uses the same input, retaining only the filter's boundary state.
    for _ in range(3):
        result = []
        for x in samples:
            y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            result.append(y)
            x2, x1, y2, y1 = x1, x, y1, y
    return result


def prepare(samples, sample_rate):
    if sample_rate < 16000 or len(samples) < 3 * sample_rate:
        raise ValueError("Expected at least three seconds at 16 kHz or higher")
    if not all(math.isfinite(x) and abs(x) <= 1 for x in samples):
        raise ValueError("Invalid normalized PCM")
    overlap = sample_rate  # One-second equal-power crossfade, no speed change.
    blended = [
        samples[-overlap + i] * math.cos(i / (overlap - 1) * math.pi / 2)
        + samples[i] * math.sin(i / (overlap - 1) * math.pi / 2)
        for i in range(overlap)
    ]
    loop = list(samples[overlap:-overlap]) + blended
    loop = filter_loop(loop, sample_rate, 100, highpass=True)
    loop = filter_loop(loop, sample_rate, 3800)
    loop = filter_loop(loop, sample_rate, 3800)
    # Fixed whole-file gain, no compressor or changing volume envelope.
    rms = math.sqrt(sum(x * x for x in loop) / len(loop))
    peak = max(abs(x) for x in loop)
    if rms == 0:
        raise ValueError("Silent source")
    gain = min(10 ** (-33 / 20) / rms, 10 ** (-15 / 20) / peak)
    return array.array("h", (round(x * gain * 32767) for x in loop))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Output already exists; choose a new file")
    if hashlib.sha256(args.source.read_bytes()).hexdigest() != SOURCE_SHA256:
        parser.error("Source fingerprint differs from the documented CC0 recording")
    with wave.open(str(args.source), "rb") as source:
        if (source.getnchannels(), source.getsampwidth(), source.getframerate()) != (2, 2, 44100):
            parser.error("Expected stereo 16-bit 44.1 kHz PCM")
        pcm = array.array("h", source.readframes(source.getnframes()))
        if sys.byteorder != "little":
            pcm.byteswap()
    mono = [(pcm[i] + pcm[i + 1]) / 65536 for i in range(0, len(pcm), 2)]
    result = prepare(mono, 44100)
    if sys.byteorder != "little":
        result.byteswap()
    # Exclusive creation protects a file appearing after the existence check.
    with args.output.open("xb") as destination:
        with wave.open(destination, "wb") as output:
            output.setparams((1, 2, 44100, len(result), "NONE", "not compressed"))
            output.writeframes(result.tobytes())
    print(f"Wrote {len(result)} frames ({len(result) / 44100:.6f} seconds)")
    print(f"SHA-256: {hashlib.sha256(args.output.read_bytes()).hexdigest()}")


if __name__ == "__main__":
    main()
