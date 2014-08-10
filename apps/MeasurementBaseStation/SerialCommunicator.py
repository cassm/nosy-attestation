import os
import sys
import time
import struct

from Tkinter import *

import DataReading
import DataSettings
import AttestationResponseMsg
import AttestationRequestMsg
from tinyos.message import *
from tinyos.message.Message import *
from tinyos.message.SerialPacket import *
from tinyos.packet.Serial import Serial

class Readings:
    who = 0
    temperature = 0
    humidity = 0
    fullSpectrum = 0
    photoSpectrum = 0

    def update(self, newVals):
        who = newVals.get_who()
        temperature = newVals.get_temperature()
        humidity = newVals.get_humidity()
        fullSpectrum = newVals.get_fullSpectrum()
        photoSpectrum = newVals.get_photoSpectrum()

currentReadings = Readings()



class DataLogger():
    benchmarking = False
    goldenChecksum = 0
    checksum = 0


    def __init__(self, motestring, volt):
        self.mif = MoteIF.MoteIF()
        self.tos_source = self.mif.addSource(motestring)
        self.mif.addListener(self, DataReading.DataReading)
        self.mif.addListener(self, AttestationResponseMsg.AttestationResponseMsg)
        
    def receive(self, src, msg):
        if msg.get_amType() == DataReading.AM_TYPE:
            #print "Node {}:\tT = {}\tH = {}\tFS = {}\tPS = {}\n".format(msg.get_who(), msg.get_temperature(), msg.get_humidity(), msg.get_fullSpectrum(), msg.get_photoSpectrum())
            currentReadings.update(msg)
            
        elif msg.get_amType() == AttestationResponseMsg.AM_TYPE:
            print "Attestation response:\n\tNode: {}\n\tNonce: {}\n\tChecksum: {}".format(msg.get_who(), msg.get_nonce(), msg.get_checksum())
            if self.benchmarking == True:
                self.goldenChecksum = msg.get_checksum()
            elif msg.get_checksum() != self.goldenChecksum:
                print "Attestation FAILED"
            else:
                print "Attestation SUCCEEDED"
        sys.stdout.flush()

    def send(self):
        smsg = DataReading.DataReading()
        smsg.set_rx_timestamp(time.time())
        self.mif.sendMsg(self.tos_source, 0xFFFF,
                         smsg.get_amType(), 0, smsg)

    def requestAttestation(self):
        who = input("Enter node ID: ")
        nonce = input("Enter nonce: ")
        smsg = AttestationRequestMsg.AttestationRequestMsg()
        smsg.set_who(who)
        smsg.set_nonce(nonce)
        self.mif.sendMsg(self.tos_source, 0xFFFF,
                         smsg.get_amType(), 0, smsg)

    def set_sample_rate(self, rate):
        print "Setting sample rate..."        
        smsg = DataSettings.DataSettings()
        smsg.set_testVal(5)
        smsg.set_sampleInterval(rate)
        #smsg.set_rx_timestamp(time.time())
        self.mif.sendMsg(self.tos_source, 0xFFFF,
                         smsg.get_amType(), 0, smsg)

    def main_loop(self):
        while 1:
            choice = raw_input("(B)enchmark or (A)ttest: ")
            if choice == 'b' or choice == 'B':
                self.benchmarking = True
                self.requestAttestation()
            elif choice == 'a' or choice == 'A':
                self.benchmarking = False
                self.requestAttestation()

            '''
            samplerate = input("Enter new sample rate: ")
            answer = raw_input("Set sample rate to {}? (Y/N): ".format(samplerate),)
            if answer == 'Y' or answer == 'y':
                self.set_sample_rate(samplerate)
            time.sleep(1)
            # send a message 1's per second
            #self.send_msg()
            '''

class FrontEnd:
    def __init__(self, master):
        
        frame = Frame(master)
        frame.pack()

        self.button=Button(
            frame, text="Exit", fg="red", command=frame.quit
            )
        self.button.pack(side=LEFT)

        self.showReads = Button(frame, text="Show Readings", command = self.show_readings)
        self.showReads.pack(side=LEFT)
    
    def show_readings(self):
        print "Node: {}".format(currentReadings.who)
        print "Temp: {}".format(currentReadings.temperature)
        print "Humd: {}".format(currentReadings.humidity)
        print "FLux: {}".format(currentReadings.fullSpectrum)
        print "PLux: {}".format(currentReadings.photoSpectrum)

def main():
    if '-h' in sys.argv or len(sys.argv) < 2:
        print "Usage:", sys.argv[0], "sf@localhost:9002", "adc_rev_volt <Volt>" 
        sys.exit()
        
    currentReadings = Readings()
    dl = DataLogger(sys.argv[1], float(sys.argv[2]), )
    root = Tk()
    app = FrontEnd(root)

    #root.mainloop()
    dl.main_loop()  # don't expect this to return...

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
