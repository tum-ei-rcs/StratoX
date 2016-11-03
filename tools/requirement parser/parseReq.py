# Requirement Parser
#
# Quick & dirty python script to parse requirements

# command line: 


# Unit System
rePrefix = '([pnumkMGTP])?'
reBaseUnit = '(m|g|s|A|K|deg)'
reExp = '(?:\^(-?\d\d?))?'
# reDerivedUnit = '(?:N|Pa|W)'  # erstmal nicht

reDim = rePrefix+reBaseUnit+reExp

reNum = '(\d+\.\d+) '
reDims = '('+reDim+'(?:\*'+reDim+')*)' # + '(?:/' + reDimMul + ')?'

reQuantity = reNum + reDims + '(?=[ .,;)]|$)'


# Requirement Structure Elements
reReqType = '(FuncReq|SafetyReq)'
reReqID = '(\w+\d+)'

reCondition = 'when ([^,]+), '
reSubject = 'the (\w+) '   # 2 words: object type, name  e.g the module "controller" 
reAction = 'shall (\w+) '
reObject = '(?:the (\w+) )?'
reConstraint = 'with (.+?)\.[^\d\w]'



# Requirements
reReqHeader = reReqType + " " + reReqID
reReqDescription = '(?:'+reCondition+')?'+reSubject+reAction+reObject+reConstraint

reReq = reReqHeader + '\\\n' + reReqDescription

gReqs = []


# finer regex
reObjType = 'system|subsystem|module|function|procedure|variable'
reQuantifier = 'all|some|one|a'


class Requirement:
	type = ""
	id = ""
	condition = "Always"
	subject = ""
	action = ""
	object = ""
	constraint = ""
	def __init__(self, id):
		self.id = id

class Unit_Type:
	val = 0.0
	exp = 0
	m = 0
	kg = 0
	s = 0
	A = 0
	K = 0
	deg = 0



def readInputFile( fileName ):
	# Open file as file object and read to string
	sourceFile = open(fileName,'r')

	# Read file object to string
	sourceText = sourceFile.read()

	# Close file object
	sourceFile.close()

	# return
	return sourceText


def parseRequirements(text):
	reqs = re.findall(reReq, text, re.DOTALL | re.MULTILINE)
	for req in reqs:
		myreq = Requirement(req[1])
		myreq.type = req[0]
		myreq.condition = req[2]
		myreq.subject = req[3]
		myreq.action = req[4]
		myreq.object = req[5]
		myreq.constraint = req[6]
		gReqs.append(myreq)
		printReq(myreq)

		parseQuantity(myreq.constraint)  # check constraints for units
		
	return text


def printReq(req):
	print ("Type:       " + req.type)
	print ("ID:         " + req.id)
	print ("Condition:  " + req.condition)
	print ("Subject:    " + req.subject)
	print ("Action:     " + req.action)
	print ("Object:     " + req.object)
	print ("Constraint: " + req.constraint)
	print ("")

def printAllReq():
	for req in gReqs:
		printReq(req)

def printQuantity(quantity):
	print "Value:                  " + repr(quantity.val) + " * 10^" + repr(quantity.exp)
	print "Units (m,kg,s,A,K,deg): (" + repr(quantity.m) + ", " + repr(quantity.kg) + ", " + repr(quantity.s) + ", " + repr(quantity.A) + ", " + repr(quantity.K) + ", " + repr(quantity.deg) + ")"
	print ""


def parseQuantity(text):
	matches = re.findall(reQuantity, text, re.DOTALL)
	for match in matches:
		myQuantity = Unit_Type()
		myQuantity.val = float(match[0])
		parseDimension(myQuantity, match[1])
		printQuantity(myQuantity)


def parseDimension(quantity, text):
	matches = re.findall(reDim, text, re.DOTALL)
	for match in matches:
		quantity = setExponent(quantity, match[0], match[1])
		quantity = setDimension(quantity, match[1], match[2])
	return quantity


def setExponent(quantity, prefixstr, dimstr):

	if (prefixstr == 'p'):
		quantity.exp += -12
	elif (prefixstr == 'n'):
		quantity.exp += -9
	elif (prefixstr == 'u'):
		quantity.exp += -6
	elif (prefixstr == 'm'):
		quantity.exp += -3
	elif (prefixstr == 'k'):
		quantity.exp += 3
	elif (prefixstr == 'M'):
		quantity.exp += 6
	elif (prefixstr == 'G'):
		quantity.exp += 9

	if (dimstr == 'g'):
		quantity.exp += -3
	return quantity


def setDimension(quantity, dimstr, expstr):
	if (expstr == ''):
		expstr = '1'
	exp = int(expstr)
	if (dimstr == 'm'):
		quantity.m += exp
	elif (dimstr == 'g'):
		quantity.kg += exp
	elif (dimstr == 's'):
		quantity.s += exp
	elif (dimstr == 'A'):
		quantity.A += exp
	elif (dimstr == 'K'):
		quantity.K += exp
	elif (dimstr == 'deg'):
		quantity.deg += exp
	return quantity





def parseObject(text):
	return text

def parseContraint(text):
	return text




def parseFile( fileName ):
	# read file
	text = readInputFile(fileName)
	fileName = os.path.basename(fileName)
	fileBaseName, ext = os.path.splitext(fileName)

	# open output file
	# if (ext != ".tex"):
	# 	print "Unknown file format: "+ext
	# 	sys.exit(1)
	# else:
	# 	output = open(fileBaseName+".md", 'w+')


	# parseFile
	parseRequirements(text)

	# write file
	#log.info("Writing Output File: "+output.name)
	#output.write(text)


# creates global log object
# @param name the name of the logger
# @param level level of logging e.g. logging.DEBUG
def setupLogging(self, name, level):
    global log
    log = logging.getLogger(name)
    log.setLevel(level)

    formatter = logging.Formatter('[%(levelname)s] %(message)s')

    sh = logging.StreamHandler()
    sh.setLevel(level)
    sh.setFormatter(formatter)
    log.addHandler(sh)

    fh = logging.FileHandler(name + ".log")
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(formatter)
    log.addHandler(fh)




# Main Program
#############################################
import logging
import fileinput
import sys
import os
import re
from collections import namedtuple



# check arguments
args = sys.argv[1:]
if len(args) == 0:
	print "Usage: python parseReq.py FILES"
	sys.exit(0)

# setupLogging(1, "parseReq", logging.DEBUG)
# log.info("Start Parsing")

for arg in args:
	parseFile(arg)
