#pragma rtGlobals=1		// Use modern global access method.
#pragma version = 1.00

// minimum and maximum LVDT extension.
Function FZminmax(i,j)
	variable i, j
	wave LVDT = root:packages:MFP3D:Force:LVDT
	wave FVResults = root:packages:MFP3D:FV:FVResults			// results file in FV folder
	WaveStats/Q LVDT											// find minimum on extend curve
	FVResults[i][j] = NaN		// since FZminmax is called first, we set all results for this point to NaN (the FVResults is set to NaN before offline analysis, but NOT when the single curve is analysed manually by mouse click)
	FVResults[i][j][%Height] = -V_max	// trigger height (in meters)
End

//	Primary based on FVAnalysis.ipf by Stefan Vinzelberg
//	20171110JR	Invers Hertz fitting to correct for gel compliance
//	20190819JR	Implementation of goodness of fit (adjusted R_bar^2)
Function FHertzModel(i,j)		
	Variable i, j
	Wave Deflection = root:packages:MFP3D:Force:Deflection	// the 1D waves which live in the Force folder
	Wave LVDT = root:packages:MFP3D:Force:LVDT
	Wave FVResults = root:packages:MFP3D:FV:FVResults		// results file in FV folder
	
	NVAR springconstant = root:packages:MFP3D:FV:g_JRspringconstant
	NVAR tipsize = root:packages:MFP3D:FV:g_JRtipsize
	NVAR dragparameter = root:packages:MFP3D:FV:g_JRdragparameter	// drag parameter
	NVAR maxforce = root:packages:MFP3D:FV:g_JRmaxforce				// max. force
	NVAR maxdelta = root:packages:MFP3D:FV:g_JRmaxdelta				// max. indentation
	
	// abort if one of the parameters is not defined properly
	If(  !NVAR_Exists(springconstant) || springconstant<=0 || !NVAR_Exists(tipsize) || !NVAR_Exists(dragparameter) || dragparameter<0 )
		Abort("No cantilever parameters specified, call \"JRInitHertzModel(...)\" first!")
	EndIf
	
	// for consistency always filtering data to 100Hz data rate
	// so e.g. for data recorded with 1kHz sample rate:
	Smooth 10, Deflection ; Resample/DOWN=10 Deflection
	Smooth 10, LVDT ; Resample/DOWN=10 LVDT
	
	WaveStats/Q Deflection
	If( !V_npnts )
		return 0	// working with waves full of NaNs massively slows down, so we abort the analysis of this curve if there are just NaNs in the wave
	EndIf
	
	WaveStats/Q LVDT
	Variable pzmax = x2pnt(LVDT, V_maxloc) 	// point of max. z-position

	SetDataFolder root:packages:MFP3D:Force	// to have the new wave all created in the same data folder

	Duplicate/O Deflection Force Indentation , Indentation_scaled , tempwave
	SetScale d 0 , 0, "m" , Deflection , Indentation , tempwave
	Indentation = LVDT - Deflection
	
	// calculating force
	Force *= springconstant ; SetScale d 0 , 0, "N" , Force
	// correcting for viscous drag using tip velocity and cantilever drag parameter
	Differentiate Indentation/D=Velocity
	Duplicate/O Force ForceCell
	ForceCell -= Velocity*dragparameter
	
	Make/O/D/N=2 W_coef = 0				// first make a line fit to find guess for contact point
	Duplicate/O Deflection tempDeflection
	CurveFit/Q/N/W=0 line, tempDeflection[0,pzmax] /D
	tempDeflection -= W_coef[0] + W_coef[1] * x	// results in curve being tilted so contact point is minimum
	WaveStats/Q/R=[pzmax,0] tempDeflection
	
	Variable fitwindow = 0.250		// time before contact point to be considered for fitting
	Variable pcontact = x2pnt( tempDeflection , V_minloc )	// first guess for the contact point
	Variable pfitwindow = pcontact - fitwindow/DimDelta(Deflection,0)
	
	WaveStats/Q/R=[pcontact,pzmax] tempDeflection
	Variable pdwellstart = x2pnt( tempDeflection , V_maxloc )	// first guess for the dwell start point
	
	Variable/G V_FitOptions = 4		// checked by Igor's FuncFit-operation (bit2 set: no param window)
	Variable/G V_FitError = 0
	
	// contact point determination: baseline from averaging over fitwindow
	// and contact point is now first point of 3*sdev away from baseline (fitwindow above guessed contact point)
	WaveStats/Q/R=[pfitwindow,pcontact] ForceCell
	Variable F0 = V_avg
	FindLevel/Q/P/R=[pfitwindow,pzmax] ForceCell , V_avg + 3*V_sdev
	pcontact = V_LevelX
	
	Variable d0 = Indentation[pcontact]
	
	Variable pztrig = pdwellstart
	
	// exclude data before/below contact and after trigger/maxforce/maxdelta using mask wave:
	Make/O/N=(numpnts(ForceCell)) MaskWave = ForceCell>F0 && Indentation>d0 && p<pztrig
	// exclude data above maximum force
	MaskWave *= ForceCell<F0+maxforce
	// exclude data above maximum indentation
	MaskWave *= Indentation<d0+maxdelta
	
	// doing normal Hertz fit with fixed contact point
	Make/O/D W_coef = { 1 , d0 , F0 } , W_sigma
	Make/O/T T_Constraints = { "K0 > 0" }
	FuncFit/Q/NTHR=0/H="011" NormalHertzFit W_coef  ForceCell /X=Indentation /D /C=T_Constraints /M=MaskWave
	Variable avalue_Hertz = W_coef[0]
	FindLevel/Q/P/R=[numpnts(MaskWave),0] MaskWave , 1	// for maximum indentation looking searching the last point analysed (important if we don't fit whole curve because using mask wave)
	Variable delta_Hertz = Indentation[V_LevelX] - d0
	// calculating adjusted R_bar^2
	tempwave = Maskwave ? ForceCell : NaN ; WaveStats/Q tempwave
	Variable Rbar2_Hertz = 1 - ( 1 - (1-V_chisq / (V_sdev^2*V_npnts)) ) * ( V_npnts - 1 ) / ( V_npnts - 1 - 1 )
	
	// doing invers fit with gel complicance free
	Make/O/D W_coef = { 1 , 1 , F0 , d0 } , W_sigma
	Make/O/T T_Constraints = {"K0 > 0","K1 > 0"}
	FuncFit/Q/NTHR=0/H="0011" InversHertzFit W_coef  Indentation[0,pztrig] /X=ForceCell /D /C=T_Constraints /M=MaskWave
	Variable avalue_Invers = abs(W_coef[0])
	Variable gelcompliance = abs(W_coef[1])	// abs because the can also be (super small) negative
	// calculating adjusted R_bar^2
	tempwave = Maskwave ? Indentation : NaN ; WaveStats/Q tempwave
	Variable Rbar2_Invers = 1 - ( 1 - (1-V_chisq / (V_sdev^2*V_npnts)) ) * ( V_npnts - 1 ) / ( V_npnts - 2 - 1 )
	
	If( !V_FitError )	// don't store the fit results if one of the fits crashed
		FVResults[i][j][%HertzModel_TrueHeight] = -LVDT[pcontact]		// contact point ("true height") in meters
		FVResults[i][j][%HertzModel_HertzYoungsModulus] = 9/16 / sqrt( tipsize ) * avalue_Hertz		// Young's modulus from normal Hertz fit in Pa
		FVResults[i][j][%HertzModel_HertzIndentation] = delta_Hertz		// indentation from normal Hertz fit in m
		FVResults[i][j][%HertzModel_InversYoungsModulus] = 9/16 / sqrt( tipsize * avalue_invers^3 )	// Young's modulus from invers Hertz fit in Pa
		FVResults[i][j][%HertzModel_GelCompliance] = gelcompliance	// gel complicance from invers fit in m/N
		FVResults[i][j][%HertzModel_HertzRbar2] = Rbar2_Hertz			// adjusted R_bar^2 for Hertz fit
		FVResults[i][j][%HertzModel_InversRbar2] = Rbar2_Invers		// adjusted R_bar^2 for invers fit
	Else
		FVResults[i][j][%HertzModel_TrueHeight] = -LVDT[pcontact]		// contact point ("true height") in meters
		FVResults[i][j][%HertzModel_HertzYoungsModulus] = -INF		// setting them to -INF to prevent function being called two times more
		FVResults[i][j][%HertzModel_HertzIndentation] = -INF
		FVResults[i][j][%HertzModel_InversYoungsModulus] = -INF
		FVResults[i][j][%HertzModel_GelCompliance] = -INF
		FVResults[i][j][%HertzModel_HertzRbar2] = -INF
		FVResults[i][j][%HertzModel_InversRbar2] = -INF
	EndIf
End


Function JRInitHertzModel(springconstant,poissonratio,tipshape,tipsize,dragparameter,[maxforce,maxdelta])
	Variable springconstant, poissonratio, tipsize, dragparameter , maxforce , maxdelta
	String tipshape
	
	If( ParamIsDefault(maxforce) )
		maxforce = INF
	EndIf
	If( ParamIsDefault(maxdelta) )
		maxdelta = INF
	EndIf

	strswitch(tipshape)	// here we print the parameters, just for check
	case "cone":
		print "Tip is cone with half cone angle = "+num2str(tipsize)+"°"
		tipsize *= pi/180	// convert to rads - we need the angle between tip axis and cone face
		break
	case "pyramid":
		print "Tip is pyramid with half face angle = "+num2str(tipsize)+"°"
		tipsize *= pi/180	// convert to rads - we need the angle between tip axis and pyramid side face NOT EDGE
		break
	case "sphere":
		print "Tip is sphere with radius = "+num2str(tipsize)+" m"
		break
	default:
		print "Tip shape must be either \"cone\", \"pyramid\" or \"sphere\"!"
		KillVariables/Z root:packages:MFP3D:FV:g_JRspringconstant		// then the offline analysis will abort!
		Return -1
		break
	endswitch
	print "k = "+num2str(springconstant)+" N/m , nu = "+num2str(poissonratio)+" , drag parameter = "+num2str(dragparameter)+" N / m/s , analyse until max. force = "+num2str(maxforce)+" N or max. indentation = "+num2str(maxdelta)+" m"

	Variable/G root:packages:MFP3D:FV:g_JRspringconstant = springconstant	// in N/m
	Variable/G root:packages:MFP3D:FV:g_JRpoissonratio = poissonratio		// usually 0.5 for cells and gels
	String/G root:packages:MFP3D:FV:g_JRtipshape = tipshape				// should be "cone" or "pyramid" or "sphere"
	Variable/G root:packages:MFP3D:FV:g_JRtipsize = tipsize				// in rads (cone/pyramid) or meters (sphere)
	Variable/G root:packages:MFP3D:FV:g_JRdragparameter = dragparameter	// drag constant of the cantilever in N / m/s
	Variable/G root:packages:MFP3D:FV:g_JRmaxforce = maxforce			// maximum force until curve is fitted in N (is set to INF if not needed or specified)
	Variable/G root:packages:MFP3D:FV:g_JRmaxdelta = maxdelta			// maximum indentation until curve is fitted in m (is set to INF if not needed or specified)
	
End


// Normal Hertz model fit function for fitting force vs. indentation
Function NormalHertzFit(w,d) : FitFunc
	Wave w
	Variable d
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(d) = a*(d-d0)^(3/2) + f0
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ f
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = d0
	//CurveFitDialog/ w[2] = f0
	If( d<w[1] )
		Return w[2]
	Else
		Return w[0]*abs(d-w[1])^(3/2) + w[2]
	EndIf
End


// New invers fit
Function InversHertzFit(w,f) : FitFunc
	Wave w
	Variable f
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(F) = a*(f-f0)^(2/3) + b*(f-f0) + d0
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ f
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = f0
	//CurveFitDialog/ w[3] = d0
	return w[0]*abs(f-w[2])^(2/3) + w[1]*(f-w[2]) + w[3]
End

