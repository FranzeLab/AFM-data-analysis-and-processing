""" AFMmeasurements_timelapse.py
Check/Amend the following:
- Directory of experimental folder (line 34)
- 'App' (approach height) (line 45)
- 'StepHeight' (line 52) which is the height in µm which the AFM head is retracted before moving
  to the next measurement position, where it is extended by StepHeight-2µm 
- Lines 58 - 62: Change default values for time lapse. Indicate "time of death", when to start first map,
  intervals between maps, when to stop measuring and number of measurement to start with (when resuming interrupted map).
  When resuming an interrupted map, the script automatically determines which map it is currently at based on the
  previous values and the current system time.
"""

# Python code for ExperimentPlanner
#JPK Script
checkVersion('SPM', 6, 1, 9)
from com.jpk.spm.afm.inst.lib import SPMScript
from com.jpk.spm.afm.inst.gui import Main as SPMMain
from com.jpk.util.jyswingutils import callSwing
from javax.swing import JFrame
from javax.swing import JOptionPane
from javax.swing import JPanel
import datetime
from datetime import time as timej
from datetime import date, tzinfo, timedelta
import os
import fileinput


def setApproachTargetHeight(targetHeight):
    callSwing( SPMMain.getApproachTargetHeightModel().setValue, targetHeight)

#Folder
Date = time.strftime("%Y.%m.%d", time.localtime())
Directory = ' '
filename = os.path.abspath(Directory+'AFMgrid_all.txt')
print(filename)
try:
    myFile = open(filename,'r')
    time.sleep(1)
    myFile.close()
except IOError: 
    quit('Error: File does not appear to exist.')

#Approach Height
App = 5.0e-05
setApproachTargetHeight(App)
ForceSpectroscopy.activateGUIMode()
ForceSpectroscopy.clearPositions()
ForceSpectroscopy.Autosave.activate(True)

#Set height of retract between measurements in µm
StepHeight = 150

#Save snapshots?
snapshots = 1 # set to e.g. 0 to disable snapshooter; set to 1 to enable snapshooter 

#Set default values
tod = "12:00"        #time of death
startT = "120"        #minutes after tod before starting first map
maxdelay = "60"        #map interval
endtime = "7:00"    #how long after tod maps continue
start = "1"            #start position

#Get inputs from user
panel = JPanel()
tod = JOptionPane.showInputDialog(panel,"Enter T.O.D. (HH:MM)",tod)
print "You entered T.O.D. = ",tod
startT = JOptionPane.showInputDialog(panel,"How many minutes after T.O.D. would you like to start the first map?",startT)
print "The first map will start",startT, "minutes after T.O.D."
maxdelay = JOptionPane.showInputDialog(panel,'What should the interval between maps be (in minutes)?',maxdelay)
print "The interval between maps will be",maxdelay,"minutes"
endtime = JOptionPane.showInputDialog(panel,"How long after T.O.D. should maps continue? HH:MM",endtime)
print "The measurements will stop after",endtime," hours. At",

# turn time input into a datetime object
splittime = tod.split(":")
htod = int(splittime[0])
mtod = int(splittime[1]) 
today = datetime.date.today()
dt_tod = datetime.datetime(today.year,today.month,today.day,htod,mtod,0)

# turn start time into a datetime object
delta1 = timedelta(0,int(startT)*60)
later = dt_tod + delta1

# Calculate end time
splittime = endtime.split(":")
hstop = int(splittime[0]) + htod
mstop = int(splittime[1]) + mtod
dstop = today.day
if mstop > 59:
    mstop = mstop-60
    hstop = hstop + 1
if hstop > 23:
    hstop = hstop - 24
    dstop = dstop + 1
ending = datetime.datetime(today.year,today.month,dstop,hstop,mstop,0)
print ending

start = JOptionPane.showInputDialog(panel,"Position to start at",start)
start = int(start)
if start == 1:
    print "All maps will start at position 1"
else :
    print "The next map will start at position",str(start), "\nSubsequent maps will start at position 1"
    
#calculate interval
interval = timedelta(0,int(maxdelay)*60)

if later > datetime.datetime.now():
    print "Waiting until ", datetime.time(later.hour, later.minute)
        
timeelapsed = 0
while timeelapsed == 0:
    time.sleep(0.1)
    timenow = datetime.datetime.now()
    if timenow > later:
       timeelapsed = 1
   
Time = time.strftime("%H.%M.%S", time.localtime())

#calculate end of first scan
interrupt = later + interval


NewApproach=1
Xold = MotorizedStage.getPosition().getX()
Yold = MotorizedStage.getPosition().getY()

SafeUp = 800e-6
# The following prevents an uncontrolled downward movement on the very first approach
DistToMove = 0

# Above which X or Y step should a new approach be made?
DistCheckTh = 200e-6

def scans(mapno):
    # Add the instructions for what should happen at each location here
    time.sleep(0.1)
    global NewApproach, VertDef1, gg, DistToMove, SafeUp
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
    Time = time.strftime("%H.%M.%S", time.localtime())
    Date2 = time.strftime("%Y.%m.%d", time.localtime())
    if snapshots==1:
        mapnostr = "%02d"%mapno
        if not os.path.exists(Directory+'/map_'+mapnostr+'/Pics/measurements/') :
            os.makedirs(Directory+'/map_'+mapnostr+'/Pics/measurements/')
        Snapshooter.saveOpticalSnapshot(Directory+'/map_'+mapnostr+'/Pics/measurements/'+Date2+'-'+Time+'.jpeg')
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

    mapno = 1
    latepoints = 0
    lastmap = 0
    while datetime.datetime.now() < ending:
        counter = 1
        if interrupt >= ending:
#            interrupt = ending # Uncomment if you want the current map to stop at the ending time
            print "Next map is the last one"
            lastmap = 1
        if datetime.datetime.now() < interrupt:
            mapnostr ="%02d"%mapno
            Spectroscopy.setOutputDirectory(Directory+'/map_'+mapnostr+'/files and labfile/')
            print "Starting map", mapno

        measured_something = 0
        myFile = open(filename,'r')
        for line in myFile:
            if datetime.datetime.now() > interrupt:
                print "The time for map",mapno,"has passed"
                break
            if datetime.datetime.now() > ending:
                latepoints = latepoints + 1
            if counter >= start:
               s = line
               x,y = s.strip().split(' ')
               xf = float(x)
               yf= float(y)
               DistCheck( xf , yf )
               time.sleep(0.1)
               ForceSpectroscopy.addPosition( xf , yf )
               print 'Position ',counter
               print 'Position X:   ' + x +' m,      Y:   ' + y +' m'
               scans(mapno)        
               measured_something=1           
            counter = counter+1
        if datetime.datetime.now() < interrupt:
            print "Waiting until", datetime.time(interrupt.hour, interrupt.minute)#, later.second)
        if lastmap == 0:
            while datetime.datetime.now() < interrupt:
                time.sleep(1)
        print ""

        interrupt = interrupt + interval
        if measured_something == 1:
            start = 1

        mapno = mapno +1
        ForceSpectroscopy.clearPositions()

    if latepoints == 1 :
        print "The last position was measured after the nominated experiment end time, which was :", ending
    elif latepoints > 1:
        print "The last", str(latepoints),"positions were measured after the nominated experiment end time, which was :", ending  
    else :
        print "" 
