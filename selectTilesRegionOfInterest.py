#

import os, shutil 
import regex as re
from argparse import ArgumentParser
import glob
import numpy as np 

#Command line parser
parser = ArgumentParser()
parser.add_argument("path", help = "Specify the path to the scan directory containing the split images (tiles).", type = str)
parser.add_argument("scanDimensions", help = "Specify the number of images in X and in Y for the entire scan", nargs = 2, type = int)
parser.add_argument("centerFrame", help = "Specify the tile to use as the center frame", nargs = 1, type = int)
parser.add_argument("regionOfInterest", help = "Specify the dimensions for the ouput region", nargs = 2, type = int)
parser.add_argument("-o", "--outPath", help = "Option to specify path to save output 'region' directories", type = str)
parser.add_argument("-p", "--scanPath", help = "Specify whether the tile numbering is horizontal snake, or not_snake. Default is snake", default = "snake", choices = ["snake", "not_snake"])
args = parser.parse_args()

filenames = glob.glob("{}/*.nd2".format(args.path))

filedict = {}
for i in filenames:
    position = re.search(r'_\d+.nd2', i).span()
    point = i[position[0]+1:position[1]-4]
    filedict[int(point)] = i

dimX = args.scanDimensions[0]
dimY = args.scanDimensions[1]

areaX = args.regionOfInterest[0]
areaY = args.regionOfInterest[1]

center = args.centerFrame[0]
 
scanArray = np.arange(0, (dimX * dimY)).reshape(dimX, dimY)

if args.scanPath == "snake":
	scanArray[range(1,dimX,2),:] = np.fliplr(scanArray[range(1,dimX,2),:])

centerX = int(np.where(scanArray == center)[0])
centerY = int(np.where(scanArray == center)[1])

regionOfInterst = scanArray[centerX - areaX//2:centerX + areaX//2, centerY - areaY//2:centerY + areaY//2].flatten()

if args.outPath is not None:
	outPath = args.outPath
else:
	outPath = args.path

outDir = '{}/region{}_{}x{}/'.format(outPath, center, areaX, areaY)

if os.path.isdir(outDir) == False:
    os.makedirs(outDir)

for i, j in enumerate(regionOfInterst):
    shutil.copy2(filedict[j], "{}tile{}_position{}.nd2".format(outDir, j, i))

print "Finished parsing {} by {} region surrounding tile {}".format(areaX, areaY, center)
        