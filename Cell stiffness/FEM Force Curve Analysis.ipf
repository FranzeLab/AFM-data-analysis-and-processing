#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Function for analyzing AFM-gel-cell-indentation FEM model 
// ...
// 20190606JR	Implementation of goodness-of-fit (adjusted Rbar^2)
Function MakeDeformationAnalysis()
	Wave Dtip
	Wave Dcenter
	Wave Dedge
	NVAR alpha	// tip opening angle in rad
	
	// removing erroneous datapoints i.e. when tip deformation larger than gel deformation + cell height (=z) , i.e. "flipped cell"
	Dtip = Dtip>Dcenter+z ? NaN : Dtip
	Dcenter = numtype(Dtip) ? NaN : Dcenter
	Dedge = numtype(Dtip) ? NaN : Dedge
	
	Make/O/N=( DimSize(Dtip,0) , DimSize(Dtip,1) , DimSize(Dtip,2) ) Euncorrected=NaN , Ecorrected=NaN , adjR2invers=NaN , adjR2=NaN , modelfactor=NaN , ceff=NaN , reff=NaN
	CopyScales/P Dtip , Euncorrected , Ecorrected , adjR2 , adjR2invers , modelfactor , ceff , reff
	
	Make/O/D W_coef
	Make/O/N=( DimSize(Dtip,3) ) tempforce=DimOffset(Dtip,3)+p*DimDelta(Dtip,3) , tempind , tempind , tempgelind
	Variable i , j , k , Egel , rcell
	For( k=0 ; k<DimSize(Dtip,2) ; k += 1 )
	For( j=0 ; j<DimSize(Dtip,1) ; j += 1 )
	For( i=0 ; i<DimSize(Dtip,0) ; i += 1 )
		tempind = Dtip[i][j][k][p]
		Egel = 10^( DimOffset(Dtip,0) + i*DimDelta(Dtip,0) )
		rcell = DimOffset(Dtip,1) + j*DimDelta(Dtip,1)
		
		WaveStats/Q tempind
		If( V_npnts>10 )
			// fitting normal Hertz / Sneddon model
			W_coef = { 1 }
			If( !NVAR_Exists(alpha) )	// if alpha not defined then we have the spherical model
				FuncFit/Q/NTHR=0 HertzFit W_coef  tempforce /X=tempind /D 
				Euncorrected[i][j][k] = W_coef[0] * 9/16
			Else	// otherwise it's the conical model
				FuncFit/Q/NTHR=0 SneddonFit W_coef  tempforce /X=tempind /D 
				Euncorrected[i][j][k] = W_coef[0] * 3/8*pi/tan(alpha)
			EndIf
			// quantifying fit quality with adjusted Rbar^2 ( see https://en.wikipedia.org/wiki/Coefficient_of_determination#Adjusted_R2 )
			WaveStats/Q tempforce
			adjR2[i][j][k] = 1 - ( 1 - (1-V_chisq / (V_sdev^2*V_npnts)) ) * ( V_npnts - 1 ) / ( V_npnts - 1 - 1 )
			
			If( i<DimSize(Dtip,0)-1 )
				tempgelind = Dtip[i][j][k][p] - Dtip[DimSize(Dtip,0)-1][j][k][p]
				W_coef={ 0 , 1 }
				CurveFit/Q/M=2/W=0/H="10" line , tempgelind /X=tempforce /D
				modelfactor[i][j][k] = W_coef[1]*Egel*rcell
			EndIf
			
			// fitting invers Hertz / Sneddon model ("CoCS model")
			W_coef = { 1 , 1 , 0 , 0 }
			If( !NVAR_Exists(alpha) )	// if alpha not defined then we have the spherical model
				FuncFit/Q/NTHR=0/H="0011" InversHertzFit W_coef  tempind /X=tempforce /D  
				Ecorrected[i][j][k] = 9/16 / W_coef[0]^(3/2)
			Else	// otherwise it's the conical model
				FuncFit/Q/NTHR=0/H="0011" InversSneddonFit W_coef  tempind /X=tempforce /D  
				Ecorrected[i][j][k] = 3/8*pi/tan(alpha) / W_coef[0]^2
			EndIf
			// quantifying fit quality with adjusted Rbar^2
			WaveStats/Q tempind
			adjR2invers[i][j][k] = 1 - ( 1 - (1-V_chisq / (V_sdev^2*V_npnts)) ) * ( V_npnts - 1 ) / ( V_npnts - 2 - 1 )
			
			reff[i][j][k] = 3/(2*pi) / Egel / W_coef[1] / rcell		// effective cell radius in units of actual radius
	//		ceff[i][j][k] = W_coef[1] * (Egel*rcell)	// effective gel compliance in units of 1/(Egel*rcell)
			ceff[i][j][k] = W_coef[1] * (1*rcell)		// effective gel compliance in units of 1/(Ecell*rcell)
		EndIf
	EndFor
	EndFor
	EndFor
//	Duplicate/O ceff ceff_model ; ceff_model = 9/(4*pi)/10^x	// gel compliance from analytical model (exact equation 6)
	Duplicate/O ceff ceff_model ; ceff_model = /10^x			// gel compliance from analytical model (approximation equation 6)
	
	// statistical analysis:
	Make/O/N=(DimSize(Dtip,1),DimSize(Dtip,2)) Ecorrected_avg=NaN , Ecorrected_sdev=NaN , Ecorrected_stiff=NaN , Euncorrected_avg=NaN , Euncorrected_sdev=NaN , Euncorrected_stiff=NaN
	SetScale/P x , DimOffset(Dtip,1) , DimDelta(Dtip,1) , Ecorrected_avg , Ecorrected_sdev , Ecorrected_stiff , Euncorrected_avg , Euncorrected_sdev , Euncorrected_stiff
	SetScale/P y , DimOffset(Dtip,2) , DimDelta(Dtip,2) , Ecorrected_avg , Ecorrected_sdev , Ecorrected_stiff , Euncorrected_avg , Euncorrected_sdev , Euncorrected_stiff
	Make/O/N=(DimSize(Dtip,0)) Ecorrected_temp
	For( k=0 ; k<DimSize(Dtip,2) ; k += 1 )
	For( j=0 ; j<DimSize(Dtip,1) ; j += 1 )
		Ecorrected_temp = Ecorrected[p][j][k]
		WaveStats/Q Ecorrected_temp
		Ecorrected_avg[j][k] = V_avg
		Ecorrected_sdev[j][k] = V_sdev
		Ecorrected_stiff[j][k] = Ecorrected_temp[numpnts(Ecorrected_temp)-1]

		Ecorrected_temp = Euncorrected[p][j][k]
		WaveStats/Q Ecorrected_temp
		Euncorrected_avg[j][k] = V_avg
		Euncorrected_sdev[j][k] = V_sdev
		Euncorrected_stiff[j][k] = Euncorrected[DimSize(Euncorrected,0)-1][j][k]
	EndFor
	EndFor
	
End // MakeDeformationAnalysis()


Function HertzFit(w,d) : FitFunc
	Wave w
	Variable d
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(d) = a*d^(3/2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ d
	//CurveFitDialog/ Coefficients 1
	//CurveFitDialog/ w[0] = a
	return w[0]*d^(3/2)
End

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

Function SneddonFit(w,d) : FitFunc
	Wave w
	Variable d
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(d) = a*d^2
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ d
	//CurveFitDialog/ Coefficients 1
	//CurveFitDialog/ w[0] = a
	return w[0]*d^2
End

Function InversSneddonFit(w,f) : FitFunc
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
	return w[0]*abs(f-w[2])^(1/2) + w[1]*(f-w[2]) + w[3]
End
