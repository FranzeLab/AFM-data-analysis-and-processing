""" AFMmeasurements_changingsettings_oneposition-manysettings.py
This script iterates over a list of measurement settings at every position, so
"go to position 1" --> "take a measurement with each of the settings in order_force-settings.txt" --> 
"go to position 2" --> "take a measurement with each of the settings in order_force-settings.txt" --> ...

Check/Amend the following:
- directory of experimental folder (line 27)
- range(1,xxx) in line 29: Set the second number to the total number of measurements points in the AFMgrid
- 'start1' (line 33) number of measurement of AFMgrid.txt to start with, set accordingly when resuming interrupted map
- range(1, xxx) in line 68: Set to the number of repetitions for going over the order_force-settings list + 1, so to measure 2x set to range(1,3)
- name of .txt file which contains the order of .force-settings, usually 'order_force-settings.txt' or 'order_force-settings_creep.txt' (line 71)
"""

# Python code for ExperimentPlanner
# JPK Script
checkVersion('SPM', 6, 1, 9)
from com.jpk.spm.afm.inst.lib import SPMScript
import os
import fileinput
ForceSpectroscopy.activateGUIMode()
ForceSpectroscopy.clearPositions()
ForceSpectroscopy.Autosave.activate(True)

# Position
if __name__ == "__main__":

    Directory = ''
    pos = 1
    for j in range(1, 93):
        # dirPath = os.path.dirname(__file__)
        filename = os.path.abspath(Directory + 'AFMgrid.txt')
        print(filename)
        start1 = 1

        try:
            # with open(filename,'r') as myFile:
            # open(filename,'r') as myFile:
            myFile = open(filename, 'r')
            for line in myFile:
                if pos >= start1:
                    s = line
                    x, y = s.strip().split(' ')
                    xf = float(x)
                    yf = float(y)
                    time.sleep(0.1)
                    ForceSpectroscopy.addPosition(xf, yf)

                    print 'Position ', pos
                    print 'Position X: ' + x + ' m, Y:   ' + y + ' m'

                    Scanner.approach()
                    Scanner.retractPiezo()
                    time.sleep(.05)

                    # Folder

                    Directory1 = Directory + str(pos) + '/'

                    if not os.path.exists(Directory1 + '/Pics/measurements/'):
                        os.makedirs(Directory1 + '/Pics/measurements/')
                    if not os.path.exists(Directory1 + '/files and labfile/'):
                        os.makedirs(Directory1 + '/files and labfile/')

                    # Set the target directory for storing the collected curves:
                    Spectroscopy.setOutputDirectory(Directory1 + '/files and labfile/')

                    # Loop 2 times over entire list without creep
                    for i in range(1, 3):

                        # Iterate over order_force-settings.txt to read in settings and take a curve
                        filename = os.path.abspath(Directory + 'order_force-settings.txt')
                        print(filename)
                        counter = 1
                        start = 1

                        myFile = open(filename, 'r')
                        for line in myFile:
                            if counter >= start:
                                s = line
                                p = s[0:-16]
                                r = s[0:-1]

                                ForceSpectroscopy.resetFilenameCounter()
                                ForceSpectroscopy.setFilenameRoot(p + '_' + str(i))

                                ForceSpectroscopy.Settings.loadSettings(Directory + r)

				Time = time.strftime("%H.%M.%S", time.localtime())
				Date2 = time.strftime("%Y.%m.%d", time.localtime())
				Snapshooter.saveOpticalSnapshot(Directory1+'/Pics/measurements/'+Date2+'-'+Time+'.jpeg')

                                ForceSpectroscopy.startScanning(seriesCount=1, endOption=ForceScanningEndOption.RETRACT_PIEZO)

                                print 'Loop ' + str(i) + ',  settings no ' + str(counter)
                                print p
                                print ' '
                                time.sleep(2)
                            counter = counter + 1

                    SPMScript.moveScanner(-200*1e-6)
                pos = pos + 1
               

        except IOError: 
            print(IOError)
            pos = pos + 1
            SPMScript.moveScanner(-200*1e-6)
