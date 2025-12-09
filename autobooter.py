#!/usr/bin/env python3

# Simple script for LINUX to enter the necessary boot mode in the MT6572-based (etc) phones
# Depends on pyserial. install pyserial via call to `python3 -m pip install pyserial`

# Usage: python3 autoboot-ln.py 
# and then connect the cable (and repeatedly short-press the power on key)

import sys
import time
from serial import Serial
import glob
import os
 

if os.geteuid() != 0:
    exit("You need to have root privileges to run this script.\nPlease try again, this time using 'sudo'. Exiting.")
 
orig_ports = set(glob.glob('/dev/ttyACM*')+glob.glob('/dev/ttyUSB*'))

#print(ports)

exitCode = 99
success = False
loop = True
numLoops = 0;
while (loop and numLoops < 1000):
    try:
        time.sleep(0.1)
        ports =  set(glob.glob('/dev/ttyACM*')+glob.glob('/dev/ttyUSB*')) - orig_ports
        numLoops += 1
        print (".",end="", flush=True)
        for port in ports:
            print("\nTrying Fastbooter on", port)
            s = None
            try:
                s = Serial(port, 115200)
                sys.stdout.write("\n")
                s.write(b"FASTBOOT")
                resp = s.read(8)
    	   
                #print (resp)
                if resp == b"READYTOO":
                    success = True
                s.close()
                s = None
                break
            except OSError as e:
                sys.stdout.write(".")
                sys.stdout.flush()
            if (s is not None):
                s.close()
    except KeyboardInterrupt:
        loop = False
        break
    if success:
        print("Entered fastboot mode on port", port)
        loop = False
        exitCode = 0
sys.exit(exitCode)
