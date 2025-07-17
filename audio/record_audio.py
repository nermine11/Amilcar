import jack
import threading
import numpy as np
import time
import struct
import os
import soundfile as sf
import gpsd

# === Config ===

channels = 2                # our hydrophone is dual mono
base_dir = "./recordings"   # folder to hold all recordings

gps_enabled = False
# Connect to the local gpsd
try:
    gpsd.connect()
    gps_enabled = True
except ConnectionRefusedError:
    print("Continuing without GPS.")
"""
put in a thread because it is slow and 
can slow down real time recording
"""
gps_lock = threading.Lock()     
latest_gps_position = None             

#client that connects to the JACK server
client      = jack.Client("Hydrophone_recorder")
print(f" Connected to JACK at {client.samplerate} Hz")
samplerate  = client.samplerate
sample_counter = 0
event = threading.Event()

#double buffering to avoid audio loss while saving every hour
active_frames = []         # current audio frames
active_markers = []         # stores (timestamp, sample_offset, (lat, lon))
buffer_lock = threading.Lock()
last_marker_second = [-1]

@client.set_process_callback
def process(frames:int):
    """
    audio receiving callback 
    Each time Jack provides a new block of audio(n frames), 
    we call this function
    Parameters:
        frames: number of samples in this block
    """
    global sample_counter, last_marker_second
    '''
    expected size of each block(should be
    equal to number of frames sent by Jack
    to the program
    '''
    assert frames == client.blocksize  
    '''
    data contains each ports data
    data = [
        array([0.01, 0.03, ..., -0.02]),  # channel 1 (left)
        array([0.00, 0.05, ..., -0.01])   # channel 2 (right)
    ]
    '''
    data = []
    for port in client.inports:
        data.append(port.get_array().copy())
    ''' 
     takes the raw audio samples in data and arranges them in
     2D array[[sample_ch1 , sample_ch2]] so that they can 
     be saved as audio
    '''
    frame = np.stack(data, axis =-1)
    '''
     only gps thread can access 
     latest_gps_position now to not corrupt data
    '''
    timestamp = time.time()
    current_second = int(timestamp)
    with gps_lock:
        gps_position = latest_gps_position
    with buffer_lock:
        active_frames.append(frame)
    if current_second != last_marker_second[0]:
        active_markers.append((timestamp, sample_counter, gps_position))
        last_marker_second[0] = current_second


    sample_counter += frames

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

def gps_poll():
    """
    get the position of the rPi using GPS
    """
    
    global latest_gps_position
    # while no shutdown flag 
    while gps_enabled and not event.is_set():
        try:
            packet = gpsd.get_current()
            if packet.mode >=2:
                with gps_lock:
                    latest_gps_position = (packet.lat, packet.lon)
        except Exception as e:
            print(f"GPS poll error {e}")
        time.sleep(1)

def write_cue_markers(filename: str, cue_points):
    """
    Inject cue markers in the wav file
    Parameters:
    filename
    cue_points
    
    """
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

def register_input_ports(client, num_channels:int):
    """
    Register input ports to be able to receive audio 
    from in_1(channel 1)
         in_2(channel 2) 
    Parameters:
        client: JACK client
        num_channels: number of channels
    """
    for channel in range(num_channels):
        client.inports.register(f"in_{channel+1}")
    
def get_current_hour_filename():
    """
    generates full output filename like ./recordings/20250715/hydrophone_20250715_13.wav
    """
    now      = time.gmtime()
    folder_by_day   = os.path.join(base_dir, time.strftime("%Y%m%d", now))
    os.makedirs(folder_by_day, exist_ok=True)
    filename = os.path.join(folder_by_day, time.strftime("hydrophone_%H%M%S.wav",now))
    return filename, now.tm_hour

def save_audio_and_markers(buffer_data, markers, filename:str):
    """
    Saves the audio buffer and embedded cue markers to the audio file
    Paramters
    buffer_data: audio frames to save
    markers: markers to inject
    filename: file to save to
    """
    if not buffer_data:
        print(f" Nothing to save for {filename}")
        return
    #concatenate all audio data
    audio_data = np.concatenate(buffer_data, axis=0)
    #write data using standard WAV RIFF
    sf.write(filename, audio_data, samplerate)
    print(f" Audio saved to {filename} ({samplerate} Hz)")
    # prepare and embed cue markers
    cue_points = []
    for timestamp, sample_offset, gps_position in markers:
        label = f"sample {sample_offset} at {time.strftime('%Y-%m-%d %H%M%S', time.gmtime(timestamp))}"
        if gps_position:
            label += f" (position: {gps_position[0]}, {gps_position[1]})"
        else:
            label += "_,_"
        cue_points.append((sample_offset, label))
        write_cue_markers(filename, cue_points)
    
# ========== Start Recording ==========

#start GPS polling in the background because GPSD is slow
threading.Thread(target=gps_poll, daemon=True).start()

'''
callback process will start now
activate the Jack Client
'''
with client:
    print("Start recording")
    register_input_ports(client, channels)
    # list of Jack system input port names(left channel and right channel)
    system_inputs = []
    for i in range (channels):
        system_inputs.append(f"system:capture_{i+1}")
    ''' 
    connect my Python input ports(in_1, in_2) to the system's
    input ports to be able to process the audio
    '''
    for port_name, inport in zip(system_inputs, client.inports):
        try:
            inport.connect(port_name)
        except jack.JackError as e:
            print(f" Failed to connect {port_name}: {e}")
    #intial filename and hour
    output_filename, current_hour = get_current_hour_filename()
    try:
        #checks if a shutdown flag has been raised(CTRL c or power cut)
        while not event.is_set():
            now = time.gmtime()
            if now.tm_hour != current_hour:
                # swap buffers for hourly rotation
                with buffer_lock:
                    buffer_to_save  = active_frames
                    markers_to_save = active_markers
                    active_frames   = []
                    active_markers   = []
                # write last hour's audio in background
                save_thread = threading.Thread(target=save_audio_and_markers,
                                               args=(buffer_to_save, markers_to_save, 
                                                    output_filename))
                save_thread.start()
                #update filename and hour
                output_filename, current_hour = get_current_hour_filename()
                time.sleep(1)
    except KeyboardInterrupt:
        print("\n Interrupted by user, Stopping recording")
        event.set() # shutdown will be called
    
#if CTRL_C has been pressed in the middle of recording
with buffer_lock:
    save_audio_and_markers(active_frames, active_markers, output_filename)
print("All done")