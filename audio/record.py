#!/usr/bin/env python3
import jack
import numpy as np
import threading
import time
import struct
import os
import soundfile as sf

# ==== Config ====
channels = 2       # our hydrophone is dual mono
base_dir = "./recordings"  # base directory for all recordings

# client that connects to the JACK server
client = jack.Client("Hydrophone-recorder")
print(f" Connected to JACK at {client.samplerate} Hz")
samplerate = client.samplerate
sample_counter = 0
event = threading.Event()

# double-buffering to avoid audio loss
active_buffer = []
active_timestamps = []
buffer_lock = threading.Lock()

@client.set_process_callback
def process(frames: int):
    """
    audio receiving callback 
    Each time Jack provides a new block of audio(n frames), we call this
    function
    Parameters:
        frames: number of samples in this block
    """
    global sample_counter
    assert frames == client.blocksize  # expected size of each block
    data = []
    for port in client.inports:
        data.append(port.get_array().copy())
    # takes the raw audio samples in data and arranges them in
    # 2D array[[sample_ch1 , sample_ch2]] so that they can 
    # be saved as stereo audio
    frame = np.stack(data, axis=-1)
    with buffer_lock:
        active_buffer.append(frame)
        active_timestamps.append((time.time(), sample_counter))
    sample_counter += frames  # update total sample count

@client.set_shutdown_callback
def shutdown(status: int, reason: str):
    """
    called if the JACK server shuts down or disconnects unexpectedly
    during recording
    Parameters:
        status: status code(error codes)
        reason: string message explaining 
    """
    print('shutdown status:', status)
    print('shutdown reason:', reason)
    event.set()

def register_input_ports(client, num_channels: int):
    """
    Register input ports to be able to receive audio 
    from in_1(channel 1)
         in_2(channel 2) 
    Parameters:
        client: JACK client
        num_channels: number of channels
    """
    for ch in range(num_channels):
        client.inports.register(f"in_{ch+1}")

# Inject cue markers
def write_cue_markers(filename: str, cue_points):
    with open(filename, 'r+b') as f:
        # go to the end of the file
        f.seek(0, 2)
        '''
        create cue chunks used to mark noteworthy sample offset
        '''
        # convert the cue to binary data
        cue_chunk_data = struct.pack('<I', len(cue_points))
        '''
        Cue points example (96000 , "sample 96000 at 2025-07-13 20:14:52")
                          (sample_offset, label)
        '''
        for i, (sample_offset, _) in enumerate(cue_points):
            # add id and sample offset 
            cue_chunk_data += struct.pack('<II', i + 1, sample_offset)
            cue_chunk_data += struct.pack('<4sIII', b'data', 0, 0, sample_offset)
        '''
            chunk ID                  :'cue'       → 4 bytes
            Chunk Data Size           : --         → 4 bytes
            Num Cue Points            : --         → 4 bytes
        '''
        f.write(b'cue ')
        f.write(struct.pack('<I', len(cue_chunk_data)))
        f.write(cue_chunk_data)
        '''
            create each label chunk containing the label(timestamp) describing
            its cue point (associated thanks to the Cue Point ID)
            chunk ID                  :'labl'      → 4 bytes
            Chunk Data Size           : --         → 4 bytes
            Cue Point ID              : --         → 4 bytes
            Text
        '''
        list_data = b''
        for i, (_, label) in enumerate(cue_points):
            label_bytes = label.encode('ascii')
            label_size = len(label_bytes) + 1
            # round to even size
            padded_size = label_size + (label_size % 2)
            list_data += b'labl'
            # chunk data size: Cue Point ID size (4 bytes)+ Text size
            list_data += struct.pack('<I', padded_size + 4)
            list_data += struct.pack('<I', i + 1)
            list_data += label_bytes + b'\x00'
            # if size is even, add null terminator
            if label_size % 2:
                list_data += b'\x00'
        '''
            create LIST chunk to contain the labels
            chunk ID                 :'LIST'      → 4 bytes
            Size                     : --         → 4 bytes
            list type ID             : adtl         → 4 bytes
            Data
        '''
        f.write(b'LIST')
        f.write(struct.pack('<I', len(b'adtl') + len(list_data)))
        # Associated Data List Chunk 
        f.write(b'adtl')
        f.write(list_data)

def get_current_hour_filename():
    """
    Generates full output filename like ./recordings/20250715/hydrophone_20250715_13.wav
    """
    now = time.gmtime()
    folder = os.path.join(base_dir, time.strftime("%Y%m%d", now))
    os.makedirs(folder, exist_ok=True)
    filename = os.path.join(folder, time.strftime("hydrophone_%H%M%S.wav", now))
    return filename, now.tm_hour

def save_audio_and_markers(buffer_data, timestamps, filename):
    """
    Saves the audio buffer and embedded cue markers to disk
    """
    if not buffer_data:
        print(f" Nothing to save for {filename}")
        return
    # concatenate all audio data
    audio_data = np.concatenate(buffer_data, axis=0)
    # write audio using standard RIFF (not RF64)
    sf.write(filename, audio_data, samplerate)
    print(f" Audio saved to {filename} ({samplerate} Hz)")

    # prepare and embed cue markers
    cue_points = []
    for ts, offset in timestamps:
        label = f"sample {offset} at {time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(ts))}"
        cue_points.append((offset, label))
    write_cue_markers(filename, cue_points)
    print(f" Cue markers embedded in {filename}")

# ========== Start Recording ==========

'''
callback process will start now
activate the Jack Client
'''
with client:
    print("Started recording")
    register_input_ports(client, channels)
    # list of Jack system input port names(left channel and right channel)
    system_inputs = []
    for i in range(channels):
        system_inputs.append(f"system:capture_{i+1}")
    ''' 
    connect my Python input port(in_1, in_2) to the system's
    input port to be able to process the audio
    '''
    for port_name, inport in zip(system_inputs, client.inports):
        try:
            inport.connect(port_name)
        except jack.JackError as e:
            print(f" Failed to connect {port_name}: {e}")

    # initial filename and hour
    output_filename, current_hour = get_current_hour_filename()

    try:
        while not event.is_set():
            now = time.gmtime()
            if now.tm_hour != current_hour:
                # swap buffers for hourly rotation
                with buffer_lock:
                    buffer_to_save = active_buffer
                    timestamps_to_save = active_timestamps
                    active_buffer = []
                    active_timestamps = []

                # write last hour's audio in background
                save_thread = threading.Thread(target=save_audio_and_markers,
                                               args=(buffer_to_save, timestamps_to_save, output_filename))
                save_thread.start()

                # update filename and hour
                output_filename, current_hour = get_current_hour_filename()

            time.sleep(1)
    except KeyboardInterrupt:
        print("\n Interrupted by user. Stopping recording.")
        event.set()

print(" Finalizing last hour...")
with buffer_lock:
    save_audio_and_markers(active_buffer, active_timestamps, output_filename)
print(" All done.")
