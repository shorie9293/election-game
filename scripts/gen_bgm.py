#!/usr/bin/env python3
"""Generate ambient BGM tracks for election-game using numpy + ffmpeg.

Creates 3 looping ambient MP3 tracks:
- village.mp3: peaceful, gentle tones (C major pentatonic)
- town.mp3: lively, energetic (F major, faster tempo)
- city.mp3: grand, majestic (C major, rich harmonics)
"""

import numpy as np
import subprocess
import os

SAMPLE_RATE = 44100
DURATION = 60  # seconds
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "bgm")


def sine_wave(freq, duration, sample_rate=SAMPLE_RATE, amplitude=0.3):
    """Generate a sine wave with fade in/out."""
    t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
    wave = amplitude * np.sin(2 * np.pi * freq * t)
    # Apply envelope (fade in/out)
    fade_samples = int(sample_rate * 0.05)
    if len(wave) > 2 * fade_samples:
        fade_in = np.linspace(0, 1, fade_samples)
        fade_out = np.linspace(1, 0, fade_samples)
        wave[:fade_samples] *= fade_in
        wave[-fade_samples:] *= fade_out
    return wave


def pad_sound(wave, start_time, total_duration, sample_rate=SAMPLE_RATE):
    """Pad the wave to start at start_time within total_duration."""
    start_sample = int(start_time * sample_rate)
    total_samples = int(total_duration * sample_rate)
    padded = np.zeros(total_samples)
    if start_sample >= total_samples:
        return padded
    end_sample = min(start_sample + len(wave), total_samples)
    actual_len = end_sample - start_sample
    if actual_len <= 0:
        return padded
    padded[start_sample:end_sample] = wave[:actual_len]
    return padded


def add_reverb(wave, decay=0.3, delay_samples=2205):
    """Simple delay-based reverb."""
    reverb = np.zeros_like(wave)
    for i in range(1, 4):
        shift = delay_samples * i
        reverb[shift:] += wave[:-shift] * (decay ** i)
    result = wave + reverb * 0.3
    # Normalize
    max_val = np.max(np.abs(result))
    if max_val > 0:
        result = result / max_val * 0.8
    return result


def generate_village():
    """Peaceful village BGM - gentle C major pentatonic arpeggios."""
    print("Generating village.mp3...")
    track = np.zeros(int(SAMPLE_RATE * DURATION))

    # C major pentatonic: C4, D4, E4, G4, A4, C5
    notes = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25]

    # Gentle arpeggios with long sustain
    for bar in range(15):
        base_time = bar * 4.0
        for i, note in enumerate([notes[0], notes[2], notes[3], notes[1]] * 3):
            t = base_time + i * 0.8
            wave = sine_wave(note, 1.5, amplitude=0.15)
            # Add harmonics
            wave += sine_wave(note * 2, 1.5, amplitude=0.05)
            wave += sine_wave(note * 3, 1.5, amplitude=0.02)
            track += pad_sound(wave, t, DURATION)

    # Soft bass drone
    bass = sine_wave(65.41, DURATION, amplitude=0.08)  # C2
    bass += sine_wave(98.00, DURATION, amplitude=0.04)  # G2
    track += bass

    track = add_reverb(track, decay=0.4, delay_samples=4410)
    return track


def generate_town():
    """Lively town BGM - F major with more rhythmic elements."""
    print("Generating town.mp3...")
    track = np.zeros(int(SAMPLE_RATE * DURATION))

    # F major: F4, G4, A4, Bb4, C5, D5, E5, F5
    notes = [349.23, 392.00, 440.00, 466.16, 523.25, 587.33, 659.25, 698.46]

    # Rhythmic pattern
    for bar in range(20):
        base_time = bar * 3.0
        pattern = [
            (notes[0], 0.3), (notes[2], 0.3), (notes[3], 0.3), (notes[1], 0.3),
            (notes[4], 0.3), (notes[2], 0.3), (notes[5], 0.3), (notes[3], 0.3),
        ]
        for i, (note, dur) in enumerate(pattern):
            t = base_time + i * 0.375
            wave = sine_wave(note, dur, amplitude=0.12)
            wave += sine_wave(note * 2, dur, amplitude=0.04)
            track += pad_sound(wave, t, DURATION)

    # Bass line walking
    bass_notes = [174.61, 196.00, 220.00, 233.08]  # F3, G3, A3, Bb3
    for bar in range(20):
        t = bar * 3.0
        # Both bass notes same duration to avoid shape mismatch
        bass = sine_wave(bass_notes[bar % 4], 3.0, amplitude=0.1)
        bass += sine_wave(bass_notes[(bar + 2) % 4], 3.0, amplitude=0.06)
        track += pad_sound(bass, t, DURATION)

    track = add_reverb(track, decay=0.25, delay_samples=2205)
    return track


def generate_city():
    """Grand city BGM - rich C major with majestic feel."""
    print("Generating city.mp3...")
    track = np.zeros(int(SAMPLE_RATE * DURATION))

    # Rich harmonic series based on C
    base = 130.81  # C3

    # Majestic chord progression: C - Am - F - G
    chords = [
        [base, base * 5/4, base * 3/2, base * 2],      # C major
        [base * 5/3, base * 2, base * 5/2, base * 3],   # Am
        [base * 4/3, base * 5/3, base * 2, base * 8/3], # F
        [base * 3/2, base * 15/8, base * 9/4, base * 3], # G
    ]

    for bar in range(15):
        chord = chords[bar % 4]
        t = bar * 4.0
        for note in chord:
            wave = sine_wave(note, 4.0, amplitude=0.1)
            # Rich harmonics for grandeur
            for h in range(2, 6):
                wave += sine_wave(note * h, 4.0, amplitude=0.03 / h)
            track += pad_sound(wave, t, DURATION)

    # Melodic line
    melody = [523.25, 587.33, 659.25, 698.46, 783.99, 698.46, 659.25, 587.33,
              523.25, 440.00, 392.00, 349.23, 392.00, 440.00, 523.25, 659.25]
    for i, note in enumerate(melody):
        t = i * 3.75
        wave = sine_wave(note, 3.0, amplitude=0.08)
        wave += sine_wave(note * 2, 3.0, amplitude=0.04)
        track += pad_sound(wave, t, DURATION)

    track = add_reverb(track, decay=0.5, delay_samples=6615)
    return track


def save_mp3(wave, filename, sample_rate=SAMPLE_RATE):
    """Save numpy array as MP3 using ffmpeg."""
    path = os.path.join(OUTPUT_DIR, filename)
    # Normalize
    max_val = np.max(np.abs(wave))
    if max_val > 0:
        wave = wave / max_val * 0.9
    # Convert to 16-bit PCM
    int_wave = (wave * 32767).astype(np.int16)
    # Stereo: duplicate mono to stereo
    stereo = np.column_stack([int_wave, int_wave])

    # Write via ffmpeg pipe
    cmd = [
        "ffmpeg", "-y",
        "-f", "s16le",
        "-ar", str(sample_rate),
        "-ac", "2",
        "-i", "pipe:0",
        "-codec:a", "libmp3lame",
        "-b:a", "128k",
        path
    ]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=subprocess.DEVNULL)
    proc.communicate(input=stereo.tobytes())
    if proc.returncode != 0:
        raise RuntimeError(f"ffmpeg failed for {filename}")
    size_kb = os.path.getsize(path) / 1024
    print(f"  Saved: {path} ({size_kb:.0f} KB)")


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("Generating election-game BGM tracks...")
    print(f"Sample rate: {SAMPLE_RATE} Hz, Duration: {DURATION}s each")
    print(f"Output: {OUTPUT_DIR}")
    print()

    # Village
    village = generate_village()
    save_mp3(village, "village.mp3")

    # Town
    town = generate_town()
    save_mp3(town, "town.mp3")

    # City
    city = generate_city()
    save_mp3(city, "city.mp3")

    print("\nAll BGM tracks generated successfully!")
    print("Files:")
    for f in ["village.mp3", "town.mp3", "city.mp3"]:
        path = os.path.join(OUTPUT_DIR, f)
        size_kb = os.path.getsize(path) / 1024
        print(f"  {f}: {size_kb:.0f} KB")


if __name__ == "__main__":
    main()
