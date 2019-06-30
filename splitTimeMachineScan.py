#

import os, shutil 
import regex as re
from argparse import ArgumentParser
import glob
import numpy as np 

#Command line parser
parser = ArgumentParser()
parser.add_argument("path", help = "Specify the path to the scan directory containing the split images (tiles).", type = str)
parser.add_argument("dimensions", help = "Specify the number of images in X and in Y", nargs = 2, type = int)
parser.add_argument("regions", help = "Specify the number of regions in X and Y to split the scan into.", nargs = 2, type = int)
parser.add_argument("-o", "--outPath", help = "Option to specify path to save output 'region' directories", type = str)
parser.add_argument("-p", "--scanPath", help = "Specify whether the tile numbering is horizontal snake, or not_snake. Default is snake", default = "snake", choices = ["snake", "not_snake"])
args = parser.parse_args()

filenames = glob.glob("{}/*.nd2".format(args.path))

filedict = {}
for i in filenames:
    position = re.search(r'_\d+.nd2', i).span()
    point = i[position[0]+1:position[1]-4]
    filedict[int(point)] = i

dimX = args.dimensions[0]
dimY = args.dimensions[1]

splitX = args.regions[0]
splitY = args.regions[1]

scanArray = np.arange(0, (dimX * dimY)).reshape(dimX, dimY)

if args.scanPath == "snake":
	scanArray[range(1,dimX,2),:] = np.fliplr(scanArray[range(1,dimX,2),:])

splitDimensionX = int(np.ceil(np.true_divide(dimX, splitX)))
splitDimensionY = int(np.ceil(np.true_divide(dimY, splitY)))

regionHolder = []

for i in xrange(splitX):
    for j in xrange(splitY):
        regionHolder.append(scanArray[i*splitDimensionX:(i+1)*splitDimensionX, j*splitDimensionY:(j+1)*splitDimensionY].flatten())

if args.outPath is not None:
	outPath = args.outPath
else:
	outPath = args.path

for i, region in enumerate(regionHolder):
    tmpOutDir = '{}/region{}/'.format(outPath, i+1)
    if os.path.isdir(tmpOutDir) == False:
    	os.makedirs(tmpOutDir)
    for j in region:
        shutil.copy2(filedict[j], tmpOutDir)
    print "Finished region {}".format(i+1)
        