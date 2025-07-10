import sounddevice as sd
import numpy as np
import wave
import json
from datetime import datetime, timezone
import os
import gpsd

# Configuration
SAMPLE_RATE = 48000  # 48kHz or 44.1 to see
OUTPUT_DIR = "hydrophone_recordings"
WAV_FILE = os.path.join(OUTPUT_DIR, "recording.wav")
JSON_FILE = os.path.join(OUTPUT_DIR, "timestamps.json")
# create output directory
os.makedirs(OUTPUT_DIR, exist_ok=True)
def initialize_gps():
    try:
        gpsd.connect()
        print("connected to GPSD")
        return True
    except Exception as e:
        print(f"GPS connection failed: {e}")
        return False

def get_gps_data():
    try:
        packet = gpsd.get_current()
        if packet.mode >= 2:  # 2D/3D fix
            return {
                "lat": packet.lat,
                "lon": packet.lon,
                "alt": packet.alt if packet.mode == 3 else None,
                "speed": packet.hspeed,
                "track": packet.track,
                "mode": packet.mode,
                "sats": packet.sats
            }
        return None
    except Exception as e:
        print(f"GPS error: {e}")
        return None

if __name__ == '__main__':
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
            #get location
            if initialize_gps():
                gps_data = get_gps_data()
            else:
                gps_data = None    
            #log timestamps and location
            log["timestamps"].append({
                "iso_time": now.isoformat(),
                "gps_time": now.timestamp(),
                "sample_offset": samples_recorded,
                "location": gps_data
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