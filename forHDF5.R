#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# if you want to view the bands 'properly', then they must be transposed and rotated
 rotate <- function(x) t(apply(t(x), 2, rev))
# then show images with
# image(rotate(<BAND_NAME>))

# get the file name and store as a variable
# g <- 'A2016002205000SWIR_EG.L2_LAC.x.hdf'
g <- args[1]
if(is.na(g)){
	print("Error, invalid or missing filename")
	quit()
}

#r Load `raster` and `rhdf5` packages and read NIS data into R
library(raster)
library(rhdf5)
library(rgdal)

# list bands in file
# h5ls(g,all=T)

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
for (i in 1:length(lat)){
	if( ( abs(49.404-lat[i]) + abs(-123.965-lon[i]) ) < ( abs(-123.965-closestLon) + abs(49.404-closestLat) ) ){
		closestVal <- i
		closestLat <- lat[i]
		closestLon <- lon[i]
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
	#print(gam[hh[i]])
}

# Step 4: Calculate averages, alert if theres not enough
epsAvg <- 0
gamAvg <- 0
if(valid<20){
	print("Error, not enough good pixels")
	epsAvg <- 0
	gamAvg <- 0
}
epsAvg <- epsVal/valid
gamAvg <- gamVal/valid

# Save values to a line in an xml file, or just output and let bash handle it?
image(rotate(epsilon))