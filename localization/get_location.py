import gpsd
import threading
import time
import os
import json

base_dir = "./locations"
gps_enabled = False

gps_lock = threading.Lock()
latest_gps_position = None

active_gps_data = {}   # current active dictionary
buffer_lock = threading.Lock()
event = threading.Event()

# === Connect to gpsd ===
try:
    gpsd.connect()
    gps_enabled = True
except ConnectionRefusedError:
    gps_enabled = False


def gps_poll():
    """
    Poll GPSD every second and store latest fix in shared variable.
    """
    global latest_gps_position
    while gps_enabled and not event.is_set():
        try:
            packet = gpsd.get_current()
            if packet.mode >= 2:
                with gps_lock:
                    latest_gps_position = (packet.lat, packet.lon)
        except Exception as e:
            pass
        time.sleep(1)


def get_current_hour_filename():
    """
    Returns a filename like: ./locations/2025-07-25/location_13-00-00.json
    """
    now = time.gmtime()
    folder = os.path.join(base_dir, time.strftime("%Y-%m-%d", now))
    os.makedirs(folder, exist_ok=True)
    filename = os.path.join(folder, time.strftime("location_%H-%M-%S.json", now))
    return filename, time.time()


def gps_logger():
    """
    Every second, record the current GPS fix (from gps_poll thread).
    """
    last_second = -1
    while not event.is_set():
        timestamp = time.time()
        current_second = int(timestamp)
        if current_second != last_second:
            last_second = current_second
            ms = int((timestamp % 1) * 1000)
            timestamp_str = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(timestamp)) + f".{ms:03d}"

            with gps_lock:
                position = latest_gps_position

            with buffer_lock:
                active_gps_data[timestamp_str] = {
                    "lat": position[0] if position else None,
                    "lon": position[1] if position else None
                }

        time.sleep(0.01)


def save_json_to_file(data, filename):
    """
    Atomically writes a dictionary to JSON using a temp file + rename.
    """
    try:
        tmp = filename + ".tmp"
        with open(tmp, "w") as f:
            json.dump(data, f, indent=2)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, filename)
    except Exception as e:
        pass


def gps_saver():
    """
    Every second: save current active buffer to disk.
    Every hour: swap buffers and rotate filename.
    """
    filename, current_hour = get_current_hour_filename()

    while not event.is_set():
        now = time.time()

        # hourly buffer/file rotation
        if now - current_hour >= 3600:
            with buffer_lock:
                buffer_to_save = dict(active_gps_data)
                active_gps_data.clear()
            # Save previous hour's file
            threading.Thread(target=save_json_to_file, args=(buffer_to_save, filename), daemon=True).start()
            # New filename for next hour
            filename, current_hour = get_current_hour_filename()
        # Every second: write active buffer to current file
        with buffer_lock:
            save_json_to_file(dict(active_gps_data), filename)
        time.sleep(1)
    # Final flush on shutdown
    with buffer_lock:
        if active_gps_data:
            save_json_to_file(dict(active_gps_data), filename)


# === Start Threads ===

threading.Thread(target=gps_poll, daemon=True).start()
threading.Thread(target=gps_logger, daemon=True).start()
threading.Thread(target=gps_saver, daemon=True).start()
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    event.set()
    time.sleep(1)
