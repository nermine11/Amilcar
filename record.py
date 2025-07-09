import sounddevice as sd
import numpy as np
import wave
import json
from datetime import datetime, timezone
import os

# Configuration
SAMPLE_RATE = 48000  # 48kHz or 44.1 to see
OUTPUT_DIR = "hydrophone_recordings"
WAV_FILE = os.path.join(OUTPUT_DIR, "recording.wav")
JSON_FILE = os.path.join(OUTPUT_DIR, "timestamps.json")

# create output directory
os.makedirs(OUTPUT_DIR, exist_ok=True)


# create WAV file in write only mode
wav = wave.open(WAV_FILE, 'wb')
wav.setnchannels(1)  #mono recording
wav.setsampwidth(2)  # 16-bit or 24 to see
wav.setframerate(SAMPLE_RATE)

# Init JSON log
log = {
    "samplerate": SAMPLE_RATE,
    "timestamps": [],
    "total_samples": 0
}

# === RECORDING LOOP ===
print(" Recording")
samples_recorded = 0

try:
    while True:
        # record 1 second of audio or float24 to see
        chunk = sd.rec(1* SAMPLE_RATE, samplerate=SAMPLE_RATE,
                       channels=1, dtype='int16')
        #waits for rec to be finished
        sd.wait()

        # save to WAV
        wav.writeframes(chunk.tobytes())

        #get time
        now = datetime.now(timezone.utc)
        #log timestamp
        log["timestamps"].append({
            "iso_time": now.isoformat(),
            "unix_time": now.timestamp(),
            "sample_offset": samples_recorded
        })
        samples_recorded += SAMPLE_RATE
        log["total_samples"] = samples_recorded

except KeyboardInterrupt:
    print("\n Stopped by user")

finally:
    wav.close()
    with open(JSON_FILE, 'w') as f:
        json.dump(log, f, indent=2)
    print(f"\n Audio saved: {WAV_FILE}")
    print(f" Timestamps saved: {JSON_FILE}")
