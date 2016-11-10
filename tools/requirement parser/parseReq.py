# Requirement Parser
#
# Quick & dirty python script to parse requirements

# command line: 




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

		UnitParser.parseQuantity(myreq.constraint)  # check constraints for units
		
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
import UnitParser
from collections import namedtuple



# check arguments
args = sys.argv[1:]
if len(args) == 0:
	print("Usage: python parseReq.py FILES")
	sys.exit(0)

# setupLogging(1, "parseReq", logging.DEBUG)
# log.info("Start Parsing")

for arg in args:
	parseFile(arg)
