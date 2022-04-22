""" AFMmeasurements_standardgrid.py
Check/Amend the following:
- Directory of experimental folder (line 25)
- 'App' (approach height) (line 37)
- 'StepHeight' (line 44) which is the height in µm which the AFM head is retracted before moving to the next measurement position, where it is extended by StepHeight-2µm 
- 'DistCheckTh' (line 58, recommended: 200) distance to the next measurement position where a SafeUp (800 µm) retraction including a new approach happens to prevent bumping sideways into tissue
- 'start' (line 160) number of measurement of AFMgrid.txt to start with, set accordingly when resuming interrupted map
"""

# Python code for ExperimentPlanner
#JPK Script
checkVersion('SPM', 6, 1, 9)
from com.jpk.spm.afm.inst.lib import SPMScript
from com.jpk.spm.afm.inst.gui import Main as SPMMain
from com.jpk.util.jyswingutils import callSwing
def setApproachTargetHeight(targetHeight):
    callSwing( SPMMain.getApproachTargetHeightModel().setValue, targetHeight)

#Disengage stage
MotorizedStage.disengage()

    # reintroduced by Julia - start
#Folder
Date = time.strftime("%Y.%m.%d", time.localtime())
Directory = ' '

import os
import fileinput
if not os.path.exists(Directory+'/Pics/measurements/') :
    os.makedirs(Directory+'/Pics/measurements/')

# Set the target directory for storing the collected curves:
Spectroscopy.setOutputDirectory(Directory+'/files and labfile/')
    # reintroduced by Julia - end

#Approach Height
App = 5.0e-05
setApproachTargetHeight(App)
ForceSpectroscopy.activateGUIMode()
ForceSpectroscopy.clearPositions()
ForceSpectroscopy.Autosave.activate(True)

#Set height of retract between measurements in µm
StepHeight = 250

#Save snapshots?
snapshots = 1 # set to e.g. 0 to disable snapshooter; set to 1 to enable snapshooter 

NewApproach=1
Xold = MotorizedStage.getPosition().getX()
Yold = MotorizedStage.getPosition().getY()

SafeUp = 800e-6
# The following prevents an uncontrolled downward movement on the very first approach
DistToMove = 0

# Above which X or Y step should a new approach be made?
DistCheckTh = 200e-6


def scans():
    # Add the instructions for what should happen at each location here
    time.sleep(0.1)
    global NewApproach, VertDef1, gg, DistToMove, SafeUp, StepHeight
    if NewApproach==1:
        VertDef1=Channels.getValue('Vertical deflection', 'volts')
        print 'New Approach'
        if DistToMove > 0 :
            SPMScript.moveScanner(SafeUp-DistToMove/3)
        Scanner.approach()
        gg = Scanner.getCurrentHeight()
        Scanner.retractPiezo()
        SPMScript.moveScanner(-StepHeight*1e-6)
        NewApproach = 0
                              
    SPMScript.moveScanner((StepHeight-2)*1e-6)
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
    if snapshots==1:
        Snapshooter.saveOpticalSnapshot(Directory+'/Pics/measurements/'+Date2+'-'+Time+'.jpeg')        # reintroduced by Julia - end
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
		
    if minHeightM >70e-6:
        #Move motors up and measure again if too near the top of the Zscanner.
        SPMScript.moveScanner(-50e-6)
        ForceSpectroscopy.startScanning(seriesCount = 1, endOption = ForceScanningEndOption.RETRACT_PIEZO)    

    
    SPMScript.moveScanner(-StepHeight*1e-6)

    print ''

def DistCheck(Xnew, Ynew):
    global NewApproach, Xold, Yold, DistCheckTh, SafeUp, DistToMove
    if Xold != 0:     
        DistToMove = ((Xold - Xnew)**2 + (Yold - Ynew)**2)**0.5
        if DistToMove > DistCheckTh:
            print 'Next coordinate too far from previous one, doing extra Z motor move.'
            SPMScript.moveScanner(-1*SafeUp)
            NewApproach = 1
        else :
            DistToMove = 0

    Xold = Xnew
    Yold = Ynew

if __name__ == "__main__":
    #dirPath = os.path.dirname(__file__)
    filename = os.path.abspath(Directory+'AFMgrid.txt')
    print(filename)
    counter = 1
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
                 #  print 'done addpos'
                 #  scans()
                 #  print 'done scans'
                   print 'Position ',counter
                   print 'Position X:   ' + x +' m,      Y:   ' + y +' m'
                   scans()                   
                counter = counter+1
               # print 'incremented counter'
    except IOError: 
        print("Error: File does not appear to exist.")   

