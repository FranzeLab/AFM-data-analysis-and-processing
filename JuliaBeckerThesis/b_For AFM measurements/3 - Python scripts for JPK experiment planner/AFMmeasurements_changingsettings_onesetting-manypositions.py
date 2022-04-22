""" AFMmeasurements_changingsettings_onesetting-manypositions.py
This script iterates over a list of positions, changing the measurement settings after a set number of measurements, like
"load settings 1" --> "go to position 1 and measure" --> "go to position 2 and measure" --> "go to position 3 and measure" -->
"load settings 2" --> "go to position 4 and measure" --> "go to position 5 and measure" --> "go to position 6 and measure" -->
"load settings 3" --> ...

Check/Amend the following:
- Directory of experimental folder (line 27)
- Name of .txt file which contains the order of .force-settings, usually 'order_force-settings.txt' or 'order_force-settings_creep.txt' (line 33)
- 'App' (approach height) (line 53)
- 'DistCheckTh' (line 65, recommended: 200) distance to the next measurement position where a SafeUp (800 µm) retraction including a new approach happens to prevent bumping sideways into tissue
- 'points_per_column' (line 165) which is the number of measurements to take with a specific setting before moving on to the next setting
- 'start' (line 166) number of measurement of AFMgrid.txt to start with, set accordingly when resuming interrupted map
"""

# Python code for ExperimentPlanner
#JPK Script
checkVersion('SPM', 6, 1, 9)
from com.jpk.spm.afm.inst.lib import SPMScript
ForceSpectroscopy.activateGUIMode()
ForceSpectroscopy.clearPositions()
ForceSpectroscopy.Autosave.activate(True)

    # reintroduced by Julia - start
#Folder
Date = time.strftime("%Y.%m.%d", time.localtime())
Directory = ' '
import os
import fileinput
import math


filename2 = os.path.abspath(Directory+'order_force-settings.txt')
bla = open(filename2,'r')
for line in bla:
    s = line
    p = s[0:-16]
    if not os.path.exists(Directory+p+'/files and labfile/') :
        os.makedirs(Directory+p+'/files and labfile/')
    if not os.path.exists(Directory+p+'/Pics/measurements/') :
        os.makedirs(Directory+p+'/Pics/measurements/')
    if not os.path.exists(Directory+p+'/Pics/calibration/') :
        os.makedirs(Directory+p+'/Pics/calibration/')
    if not os.path.exists(Directory+p+'/elasticity maps/') :
        os.makedirs(Directory+p+'/elasticity maps/')
    if not os.path.exists(Directory+p+'/region analysis/') :
        os.makedirs(Directory+p+'/region analysis/')


    # reintroduced by Julia - end

#Approach Height
App = 5.0e-05


NewApproach=1
Xold = 0
Yold = 0

SafeUp = 800e-6
# The following is a lazy means of preventing an uncontrolled downward movement on the very first approach
DistToMove = SafeUp*3

# Above which X or Y step should a new approach be made?
DistCheckTh = 200e-6


def scans():
    # Add the instructions for what should happen at each location here
    time.sleep(0.1)
    global NewApproach, VertDef1, gg, DistToMove, SafeUp
    if NewApproach==1:
        VertDef1=Channels.getValue('Vertical deflection', 'volts')
        print 'New Approach'
        SPMScript.moveScanner(SafeUp-DistToMove/3)
        Scanner.approach()
        gg = Scanner.getCurrentHeight()
        Scanner.retractPiezo()
        SPMScript.moveScanner(-150*1e-6)
        NewApproach = 0
                              
    SPMScript.moveScanner(148*1e-6)
    time.sleep(.05)
    VertDef2=Channels.getValue('Vertical deflection', 'volts')
        
    SUMMME=Channels.getValue('photo-sum', 'volts')
        
    if SUMMME<0.5:
        SPMScript.moveScanner(-250*1e-6)
        Scanner.approach()
        gg = Scanner.getCurrentHeight()
        Scanner.retractPiezo()
            
       
    if abs(VertDef1-VertDef2)>2.5:
        print 'New Approach'
        SPMScript.moveScanner(-100*1e-6)
        Scanner.approach()
        gg = Scanner.getCurrentHeight()
        Scanner.retractPiezo()
        time.sleep(.05)
        VertDef1=Channels.getValue('Vertical deflection', 'volts')
        print VertDef1
    else:
        VertDef1=VertDef2
           
    # Start the spectroscopy scan(s).  The parameter specifies the
    # number of scans to take at the current position:
        # reintroduced by Julia - start
    Time = time.strftime("%H.%M.%S", time.localtime())
    Date2 = time.strftime("%Y.%m.%d", time.localtime())
    Snapshooter.saveOpticalSnapshot(Directory1+'/Pics/measurements/'+Date2+'-'+Time+'.jpeg')
        # reintroduced by Julia - end
    ForceSpectroscopy.startScanning(seriesCount = 1, endOption = ForceScanningEndOption.RETRACT_PIEZO)
    series = ForceSpectroscopy.getCurrentSeries()
    segments = series.segments 
    segment = segments['Retract'] 
    data = segment.getData('capacitiveSensorHeight','nominal')
    data2 = segment.getData('Height','nominal')
    minHeightM = data.minimumValue
    minHeight = data2.minimumValue
    print 'Minimum PiezoHeight was         ' + str(minHeight*1e6) +'um'
    if minHeight<1e-06:
        #Re-approach if too close to bottom of scanner and measure again
        Scanner.approach()
        minHeight = Scanner.getCurrentHeight()
        Scanner.retractPiezo()
        ForceSpectroscopy.startScanning(seriesCount = 1, endOption = ForceScanningEndOption.RETRACT_PIEZO)
        
    if abs(gg-minHeight)>0.5e-05:
        #Adjust Z motors if there is a significant difference between the minHeight and the height of 
        #the last full approach. This helps adapt to sloping surfaces. It then sets the value of height 
        #to the App value above to try to keep in the desired range
        SPMScript.moveScanner(gg-minHeight)
        gg = App
		
    if minHeightM > 70e-6:
        #Move motors up and measure again if too near the top of the Zscanner.
        SPMScript.moveScanner(-50e-6)
        ForceSpectroscopy.startScanning(seriesCount = 1, endOption = ForceScanningEndOption.RETRACT_PIEZO)    

    
    SPMScript.moveScanner(-150*1e-6)

    print ''

def DistCheck(Xnew, Ynew):
    global NewApproach, Xold, Yold, DistCheckTh, SafeUp, DistToMove
    if Xold != 0:     
        DistToMove = ((Xold - Xnew)**2 + (Yold - Ynew)**2)**0.5
        if DistToMove > DistCheckTh:
            print 'Next coordinate too far from previous one, doing extra Z motor move.'
            SPMScript.moveScanner(-1*SafeUp)
            NewApproach = 1
    Xold = Xnew
    Yold = Ynew

if __name__ == "__main__":
    #dirPath = os.path.dirname(__file__)
    filename = os.path.abspath(Directory+'AFMgrid.txt')
    filename2 = os.path.abspath(Directory+'order_force-settings.txt')
    print(filename)
    print(filename2)
    counter = 1
    points_per_column = 46.0 	# .0 important here, do not remove!
    start = 1
    
    
    
    try:
        #with open(filename,'r') as myFile:
        #open(filename,'r') as myFile:   
        myFile = open(filename,'r')
        for line in myFile:
                if counter >= start:
                   s = line
                   x,y = s.strip().split(' ')
                   xf = float(x)
                   yf= float(y)
                   DistCheck( xf , yf )
                   time.sleep(0.1)
                   ForceSpectroscopy.addPosition( xf , yf )

                   condition = int(math.ceil(counter/points_per_column))
                   bla = open(filename2, 'r')
                   setting = bla.readlines()[condition-1]
                   setting2 = setting[0:-1]
                   ForceSpectroscopy.Settings.loadSettings(Directory+setting2)

		   # Set the target directory for storing the collected curves:
                   Directory1 = Directory + setting2[0:-15]
                   Spectroscopy.setOutputDirectory(Directory1+'/files and labfile/')   

                 #  print 'done addpos'
                 #  scans()
                 #  print 'done scans'

                   print 'Position ',counter
                   print 'Position X:   ' + x +' m,      Y:   ' + y +' m'
                   print 'with ' + setting2
		   scans()                   
                counter = counter+1
               # print 'incremented counter'
    except IOError: 
        print("Error: File does not appear to exist.")   

