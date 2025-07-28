#!/bin/bash


sudo systemctl start reduce_latency.service 
sudo systemctl start jack_server
sudo systemctl start record_audio.timer
