# Unit Parser Module
#
# Quick & dirty python script to parse si-units

# Main Program
#############################################
import re


# Control
FLAG_DERIVED=True
FLAG_FULL_NAMES=True


# Unit System

# LEXER

MUL='[⋅*]'
POW='(?:\^|\*\*|)'
#EXP='[eE]'
SIGN='[-+]'

NUM='{SIGN}?\d+(?:\.\d+)?'.format(**locals())


MANT=NUM
EXP='(?:[eE]| ?\* ?10{POW}(\(?{NUM}\)))'.format(**locals())
FLOAT='(({MANT})(?:{EXP})?)'.format(**locals())

# num part
# -----------------------------------
reFloatNum = '([-+]?\d+\.\d+)'
reFloatExp = '(?:[eE]([-+]?\d\d?)| ?\* ?10\^(\(?[-+]?\d\d?\)?))?'
reFloat = '(' + reFloatNum + reFloatExp + ')'


print(reFloat)
print(FLOAT)

# dimesnion part
# -----------------------------------
rePrefix = '[zafpnumkMGTPEZ]'
reBaseUnit = 'm|g|s|A|K|deg'
reDerivedUnit = 'Hz|N|Pa|J|W|V|C|Ω|F|H|Wb|T'
reUnit = reBaseUnit

rePrefixFull = 'zepto|atto|femto|pico|nano|micro|milli|kilo|mega|giga|tera|peta|exa|zetta'
reBaseUnitFull = 'meter|gram|second|ampere|kelvin|degree'
reDerivedUnitFull= 'hertz|newton|pascal|joule|watt|volt|coulomb|ohm|farad|henry|weber|tesla'

if(FLAG_FULL_NAMES):
	rePrefix = rePrefixFull
	if(FLAG_DERIVED):
		reUnit = '{reBaseUnitFull}|{reDerivedUnitFull}'.format(**locals())
	else:
		reUnit = reBaseUnitFull
else:
	if(FLAG_DERIVED):
		reUnit = '{reBaseUnit}|{reDerivedUnit}'.format(**locals())
	else:
		reUnit = reBaseUnit

reExp = '{POW}({NUM})'.format(**locals())
reExp2 = '([⁺⁻]?[⁰¹²³⁴⁵⁶⁷⁸⁹]+)'

# dimesnion part
# -----------------------------------

# expansion: "{name} is a {adjective} {noun} that {verb}".format(**locals())
# hanning%(num)s.pdf' % locals()
reDim = '({rePrefix})?({reUnit})(?:{reExp}|{reExp2})?'.format(**locals())

reDims = '('+reDim+'(?: ?[*⋅] ?'+reDim+')*)' # + '(?:/' + reDimMul + ')?'

reQuantity = FLOAT + ' ' + reDims + '(?=[ .,;)]|$)'


class Unit_Type:
	val = 0.0
	exp = 0
	m = 0
	kg = 0
	s = 0
	A = 0
	K = 0
	deg = 0


def printQuantity(quantity):
	print("Value:                  " + repr(quantity.val) + ", exp: " + repr(quantity.exp) )
	print("Units (m,kg,s,A,K,deg): (" + repr(quantity.m) + ", " + repr(quantity.kg) + ", " + repr(quantity.s) + ", " + repr(quantity.A) + ", " + repr(quantity.K) + ", " + repr(quantity.deg) + ")")
	print("")


def parseQuantity(text):
	matches = re.findall(reQuantity, text, re.DOTALL)
	for match in matches:
		print(match)
		myQuantity = Unit_Type()
		myQuantity.val = parseValue(match[0])
		parseDimension(myQuantity, match[3])
		printQuantity(myQuantity)

def parseValue(text):
	match = re.search(FLOAT, text)
	valstr = match.group(2)
	if (match.group(3) != None):
		valstr += 'e'+match.group(3)
	return float(valstr)


def parseDimension(quantity, text):
	matches = re.findall(reDim, text, re.DOTALL)
	for match in matches:
		quantity = setExponent(quantity, match[0], match[1])
		quantity = setDimension(quantity, match[1], match[2]+match[3])
	return quantity


def setExponent(quantity, prefixstr, dimstr):

	if (prefixstr == 'p'):
		quantity.exp += -12
		quantity.val *= 10.0**-12
	elif (prefixstr == 'n'):
		quantity.exp += -9
		quantity.val *= 10.0**-9
	elif (prefixstr == 'u'):
		quantity.exp += -6
		quantity.val *= 10.0**-6
	elif (prefixstr == 'm'):
		quantity.exp += -3
		quantity.val *= 10.0**-3
	elif (prefixstr == 'k'):
		quantity.exp += 3
		quantity.val *= 10.0**3
	elif (prefixstr == 'M'):
		quantity.exp += 6
		quantity.val *= 10.0**6
	elif (prefixstr == 'G'):
		quantity.exp += 9
		quantity.val *= 10.0**9

	if (dimstr == 'g'):
		quantity.exp += -3
		quantity.val *= 10.0**-3

	#quantity.val = quantity.val * 10.0**quantity.exp
	return quantity


def setDimension(quantity, dimstr, expstr):
	if (expstr == ''):
		expstr = '1'
	elif (re.search('[⁰¹²³⁴⁵⁶⁷⁸⁹]', expstr, re.UNICODE)):
		expstr = parseSupValue(expstr)

	exp = int(expstr)

	if(FLAG_FULL_NAMES):
		if (dimstr == 'meter'):
			quantity.m += exp
		elif (dimstr == 'gram'):
			quantity.kg += exp
		elif (dimstr == 'second'):
			quantity.s += exp
		elif (dimstr == 'ampere'):
			quantity.A += exp
		elif (dimstr == 'kelvin'):
			quantity.K += exp
		elif (dimstr == 'degree'):
			quantity.deg += exp

		# derived
		if (FLAG_DERIVED):
			if (dimstr == 'hertz'):
				quantity.s += -1 * exp
			elif (dimstr == 'newton'):
				quantity.kg += 1 * exp
				quantity.m += 1 * exp
				quantity.s += -2 * exp
			elif (dimstr == 'pascal'):
				quantity.kg += 1 * exp
				quantity.m += -1 * exp
				quantity.s += -2 * exp
			elif (dimstr == 'joule'):
				quantity.kg += 1 * exp
				quantity.m += 2 * exp
				quantity.s += -2 * exp
			elif (dimstr == 'watt'):
				quantity.kg += 1 * exp
				quantity.m += 2 * exp
				quantity.s += -3 * exp
			elif (dimstr == 'volt'):
				quantity.kg += 1 * exp
				quantity.m += 2 * exp
				quantity.A += -1 * exp
				quantity.s += -3 * exp
			elif (dimstr == 'coulomb'):
				quantity.A += 1 * exp
				quantity.s += 1 * exp
			elif (dimstr == 'ohm'):
				quantity.kg += 1 * exp
				quantity.m += 2 * exp
				quantity.A += -2 * exp
				quantity.s += -3 * exp
			elif (dimstr == 'farad'):
				quantity.kg += -1 * exp
				quantity.m += -2 * exp
				quantity.A += 2 * exp
				quantity.s += 4 * exp
			elif (dimstr == 'henry'):
				quantity.kg += 1 * exp
				quantity.m += 2 * exp
				quantity.A += -2 * exp
				quantity.s += -2 * exp
			elif (dimstr == 'weber'):
				quantity.kg += 1 * exp
				quantity.m += 2 * exp
				quantity.A += -1 * exp
				quantity.s += -2 * exp
			elif (dimstr == 'tesla'):
				quantity.kg += 1 * exp
				quantity.A += -1 * exp
				quantity.s += -2 * exp


	else:
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

		# derived
		if (FLAG_DERIVED):
			if (dimstr == 'Hz'):
				quantity.s += -1 * exp
			elif (dimstr == 'N'):
				quantity.kg += 1 * exp
				quantity.m += 1 * exp
				quantity.s += -2 * exp
			elif (dimstr == 'Pa'):
				quantity.kg += 1 * exp
				quantity.m += -1 * exp
				quantity.s += -2 * exp
			elif (dimstr == 'J'):
				quantity.kg += 1 * exp
				quantity.m += 2 * exp
				quantity.s += -2 * exp
			elif (dimstr == 'W'):
				quantity.kg += 1 * exp
				quantity.m += 2 * exp
				quantity.s += -3 * exp
			elif (dimstr == 'V'):
				quantity.kg += 1 * exp
				quantity.m += 2 * exp
				quantity.A += -1 * exp
				quantity.s += -3 * exp
			elif (dimstr == 'C'):
				quantity.A += 1 * exp
				quantity.s += 1 * exp
			elif (dimstr == 'Ω'):
				quantity.kg += 1 * exp
				quantity.m += 2 * exp
				quantity.A += -2 * exp
				quantity.s += -3 * exp
			elif (dimstr == 'F'):
				quantity.kg += -1 * exp
				quantity.m += -2 * exp
				quantity.A += 2 * exp
				quantity.s += 4 * exp
			elif (dimstr == 'H'):
				quantity.kg += 1 * exp
				quantity.m += 2 * exp
				quantity.A += -2 * exp
				quantity.s += -2 * exp
			elif (dimstr == 'Wb'):
				quantity.kg += 1 * exp
				quantity.m += 2 * exp
				quantity.A += -1 * exp
				quantity.s += -2 * exp
			elif (dimstr == 'T'):
				quantity.kg += 1 * exp
				quantity.A += -1 * exp
				quantity.s += -2 * exp

	return quantity


def parseSupValue(utfExpStr):
	SUP = str.maketrans("⁺⁻⁰¹²³⁴⁵⁶⁷⁸⁹", "+-0123456789")
	SUB = str.maketrans("₀₁₂₃₄₅₆₇₈₉", "0123456789")
	return utfExpStr.translate(SUP)






