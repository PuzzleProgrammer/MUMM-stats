#!/usr/bin/env Rscript

# if you want to view the bands 'properly', then they must be transposed and rotated
rotate2 <- function(x) t(apply(t(x), 2, rev))
# then show images with
# image(rotate2(<BAND_NAME>))

analyze <- function(g){
	# read in epsilon values
	epsilon <- h5read(g,'Epsilon_SingleScatter')

	# read in gamma values
	gam <- h5read(g,'Gamma')

	# read in array of latitude co-ordinates
	lat <- h5read(g,'lat')

	# read in array of longitude co-ordinates
	lon <- h5read(g,'lon')

	# 5X5 pixel box average, centered at 49.404 N, -123.965 W
	# Step 1: find the index closest to 49.404 N, -123.965 W
	closestLat <- 0.0
	closestLon <- 0.0
	closestVal <- 0
	close <- 123.965+49.404
	for (i in 1:length(lat)){
		if( ( abs(49.404-lat[i]) + abs(-123.965-lon[i]) ) < close ){
			closestVal <- i
			closestLat <- lat[i]
			closestLon <- lon[i]
			close <- abs(-123.965-closestLon) + abs(49.404-closestLat)
		}
	}
	# Step 2: get 24 surrounding indices
	x <- ((closestVal-1) %%  dim(lat)[1])+1
	y <- ((closestVal-1) %/% dim(lat)[1])+1

	# hx is a matrix of x co-ords, hy is a matrix of y co-ords
	hx<-matrix(0,5,5)
	hy<-matrix(0,5,5)
	hh<-matrix(0,5,5) 
	for(i in 1:5){
		for(j in 1:5){
			hx[i,j] <- x+i-2
			hy[i,j] <- y+j-2
			hh[i,j] <- ((x+i-2)-1)+(((y+j-2)-2)*dim(lat)[1])
		}
	}

	# Step 3: pull 25 values for gamma, epsilon and count valid
	valid <- 0
	epsVal <- 0
	gamVal <- 0
	for (i in 1:25){
		if(epsilon[hh[i]]!=1){
			valid <- valid+1
			epsVal <- epsVal+epsilon[hh[i]]
			gamVal <- gamVal+gam[hh[i]]
		}
	}

	# Step 4: Calculate averages, alert if theres not enough
	epsAvg <- 0
	gamAvg <- 0
	if(valid<20){
		cat(c(g,": Error, not enough good pixels: ",valid,"\n"))
		epsAvg <- NA
		gamAvg <- NA
	}
	else{
		epsAvg <- epsVal/valid
		gamAvg <- gamVal/valid
	}

	H5close()
	return(list("valid" = valid, "eps" = epsAvg, "gamm" = gamAvg))
}


# # # # # # # # # # # # # # # # # # # # #
# # #     ACTUAL PROGRAM START      # # #
# # # # # # # # # # # # # # # # # # # # #

args = commandArgs(trailingOnly=TRUE)

#r Load `raster` and `rhdf5` packages and read NIS data into R
library(raster)
library(rhdf5)
library(rgdal)

# list bands in file
# h5ls(g,all=T)

# get the file name and store as a variable
# g <- 'A2016002205000SWIR_EG.L2_LAC.x.hdf'
f <- args[1]
sink(file="Epsilon_Gamma_values.csv",append=FALSE,split=FALSE)
cat(c("Valid pixels,File name,Epsilon average,Gamma average\n"))
sink()
if(is.na(f)){
	for(g in list.files(pattern="SWIR_EG.L2_LAC.x.hdf")){
		output <- analyze(g)

		# Step 5: Save to an Excel Comma Seperated Values sheet
		sink(file="Epsilon_Gamma_values.csv",append=TRUE,split=FALSE)
		cat(c(output$valid,",",g,",",output$eps,",",output$gamm,"\n"))
		sink()
	}
}else{
	output <- analyze(f)
	cat(c("\nFile name: ",f,"\nNumber of 'good' pixels: ",output$valid,"\nEpsilon Average: ",output$eps,"\nGamma Average: ",output$gamm,"\n\n"))
}

# Veiwing a subset of the 'map':

#h<-matrix(0,101,101)
#for(i in 1:101){
# for(j in 1:101){
#  h[i,j]<-((x+i-50)-1)+(((y+j-50)-2)*dim(lat)[1])
#}}
#image(rotate2(matrix(epsilon[h],101,101)))