#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function MakeVerticalCorrelation( channel , startfraction , endfraction )
	Variable channel	// channel to consider
	Variable startfraction	// profile start point to analyse (fraction of image height, from bottom) ( e.g. 1/10 )
	Variable endfraction	// profile end point to analyse (fraction of image height, from bottom) ( e.g. 1/2 or 2/3 )
	
	Wave imagesequence		// image sequence stack data
	Variable npx = DimSize(imagesequence,0) , npz = DimSize(imagesequence,1)	// pixel numbers
	
	// for inspection show a horizontal line to indicate fractions
	Make/O/N=( npx ) startfractionline=DimOffset(imagesequence,01)+DimDelta(imagesequence,1)*startfraction*npz , endfractionline = DimOffset(imagesequence,1)+DimDelta(imagesequence,1)*endfraction*npz
	SetScale/P x , DimOffset(imagesequence,0) , DimDelta(imagesequence,0) , "m" , startfractionline , endfractionline
	SetScale d 0 , 0 , "m" , startfractionline , endfractionline
	
	// for inspection show vertical sections
	Make/O/N=( npz ) referencesection=NaN , shiftsection=NaN
	SetScale/P x , DimOffset(imagesequence,1) , DimDelta(imagesequence,1) , "m" , referencesection , shiftsection
	
	// waves for profiles to store
	Make/O/N=( npx , DimSize(imagesequence,3) ) deformation=NaN
	SetScale/P x , DimOffset(imagesequence,0) , DimDelta(imagesequence,0) , "m" , deformation
	SetScale/P y , DimOffset(imagesequence,3) , DimDelta(imagesequence,3) , "N" , deformation
	SetScale d 0 , 0 , "m" , deformation
	
	// also show layer for inspection
	Make/O/N=( DimSize(imagesequence,0) , DimSize(imagesequence,1) ) showlayer=NaN
	CopyScales/P imagesequence showlayer
	
	// getting the noise level to distinguish if there are structures in the profile
	showlayer[][0,startfraction*npz] = imagesequence[p][q][channel][0]
	WaveStats/Q showlayer
	Variable noiselevel = V_sdev
	
	// compare force-layer with zero-force layer
	Variable i , j
	For( j=1 ; j<DimSize(deformation,1) ; j+=1 )	// going through the forces
		showlayer = imagesequence[p][q][channel][j]	// show current layer for inspection
		For( i=0 ; i<npx ; i+=1 )	// x-pixels
			referencesection[startfraction*npz,endfraction*npz] = imagesequence[i][p][channel][0]	//section with zero force
			shiftsection = imagesequence[i][p][channel][j]	// section with force we shift to find the deformation
			WaveStats/Q referencesection
			If( V_sdev > 5*noiselevel )	// only do correlation analysis if there is some structure in the section
				// finding the deformation either by fitting the zero-force (reference)section with the force-section with a shift
		//		Make/O/D W_coef = { 0e-6 }
		//		FuncFit/NTHR=0/N/Q/W=2 ShiftFit W_coef  referencesection /D 
		//		deformation[i][j] = W_coef[0]
				// or by manual chi-squared analysis
				deformation[i][j] = AnalyseChiSquared()
			EndIf
//			DoUpdate	// for inspection
		EndFor
	EndFor
End // MakeVerticalCorrelation( channel , startfraction , endfraction )


// Function to determine deformation by manual chi-squared analysis 
Function AnalyseChiSquared()
	Wave referencesection
	Wave shiftsection
	
	// wave to store chi-squared vs. shift distance
	Make/O/N=( 15e-6 / DimDelta(shiftsection,0) ) chisquared=NaN
	SetScale/P x , -10e-6 , DimDelta(shiftsection,0) , "m" , chisquared
	
	Duplicate/O referencesection tempsection fit_fit_chisquared
	Variable i , dz
	For( i=1 ; i<numpnts(chisquared) ; i+=1 )	// going through shift distance values
		dz = pnt2x(chisquared,i)	// shift distance in meters
		tempsection = ( referencesection(x) - shiftsection(x+dz) )^2	// curve with squared difference between
		WaveStats/Q tempsection								// between zero-force reference section and shifted force-section
		chisquared[i] = V_avg / V_npnts		// normalize for number of points
	EndFor
	
	// remove all chi-square values exept 6 lowest points
	Make/O W_QuantileValues
	StatsQuantiles/iNaN/QW/Q chisquared
	WaveStats/Q chisquared
	chisquared = W_QuantileValues>6/numpnts(chisquared)*100 ? NaN : chisquared
	// then fit polynomial of order 6 to get accurate estimate of optimal shift
	Make/O fit_chisquared
	CurveFit/M=2/W=0/Q poly 6, chisquared /D
	WaveStats/Q fit_chisquared
	Return V_minloc
End // AnalyseChiSquared()
