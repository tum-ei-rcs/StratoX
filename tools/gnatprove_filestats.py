#!/usr/bin/python

# This script parses GNATprove output and gives per-file coverage statistics,
# as well as overall statistics
#
# (C) 2016 TU Muenchen, RCS, Martin Becker <becker@rcs.ei.tum.de>

import sys, getopt, os, time, math, re, datetime, numpy;
import pprint;

#######################################
#     FUNCTION DEFINITIONS
#######################################

def file2unit(filename):
    """
    transform file name into GNAT unit name
    """

    unitname = os.path.splitext(filename)[0]
    return unitname.lower()

def get_stdout_stats(inputfile):
    """
    parse output of stdout from gnatprove
    """
    if os.stat(inputfile).st_size == 0: return None

    unit = ""
    unit_pre = ""
    units = {}
    if True: #try:
      with open(inputfile, 'r+') as f:
        l = 0
        for line in f:
            l = l + 1
            # new unit?
            match = re.search(r'^([^\s:]+):(\d+):(\d+).*', line, re.MULTILINE)
            if match:
                filename = match.group(1)
                srcline = match.group(2)
                srccol = match.group(3)

                unit = file2unit(filename)
                if unit != unit_pre:
                    unit_pre = unit
                    unitinfo = {"props":0, "proven":0}
                    if unit: units[unit]=unitinfo

            match = re.search(r'^.*: (medium|high|low): .*$', line, re.MULTILINE)
            if match:
                unitinfo["props"] = unitinfo["props"] + 1

            match = re.search(r'^.*: info: .*$', line, re.MULTILINE)
            if match:
                unitinfo["props"] = unitinfo["props"] + 1
                unitinfo["proven"] = unitinfo["proven"] + 1
                                
        if unit: units[unit]=unitinfo
        return units
    else: #except:
        print "ERROR reading file " + inputfile
        return None

def get_report_stats(inputfile):
    """
    parse the report from gnatprove
    """
    if os.stat(inputfile).st_size == 0: return None

    unit_pre = ""
    subname_pre =""

    units = {}
    if True: #try:
      with open(inputfile, 'r+') as f:
        l = 0
        for line in f:
            l = l + 1
            # new unit?
            match = re.search(r'^in unit ([^\s:,]+)', line, re.MULTILINE)
            if match:
                unit = match.group(1).lower()
                if unit != unit_pre:
                    unit_pre = unit
                    unitinfo = {"subs":0, "props":0, "proven":0, "skip":0}
                    if unit: units[unit]=unitinfo
            else:
                proc = False

                # location
                match = re.search(r'^.*\s+([^\s:]+) at ([^\s:]+):(\d+)', line, re.MULTILINE)
                if match:
                    proc = True
                    funcname = match.group(1)
                    filename = match.group(2)
                    srcline = match.group(3)
                    subname = filename + ":" + funcname + ":" + srcline
                    if subname != subname_pre:
                        subname_pre = subname
                        unitinfo["subs"] = unitinfo["subs"] + 1

                
                # some are proven         
                match = re.search(r'^.* (\d+) checks out of (\d+) proved$', line, re.MULTILINE)
                if match:
                    proc = True
                    pgood = match.group(1)
                    ptotal = match.group(2)
                    try:
                        succ = int(float(pgood) / float(ptotal) * 100)
                    except:
                        succ = 0.0
                    #print "  " + funcname + ":" + srcline + " => " + pgood + " of " + ptotal + " proved (" + str(succ) + "%)"
                    unitinfo["props"] = unitinfo["props"] + int(ptotal)
                    unitinfo["proven"] = unitinfo["proven"] + int(pgood)

                # all are proven
                match = re.search(r'^.* and proved \((\d+) checks\)$', line, re.MULTILINE)
                if match:
                    proc = True
                    pgood = match.group(1)
                    ptotal = pgood
                    succ = 100
                    unitinfo["props"] = unitinfo["props"] + int(ptotal)
                    unitinfo["proven"] = unitinfo["proven"] + int(pgood)
                    #print "  " + funcname + ":" + srcline + " => " + ptotal + " of " + ptotal + " proved (" + str(succ) + "%)"

                # sub skipped
                match = re.search(r'^.* skipped', line, re.MULTILINE)
                if match:
                    proc = True
                    #print "  " + funcname + ":" + srcline + " => SKIPPED"
                    unitinfo["skip"] = unitinfo["skip"] + 1

                if not proc:
                    #print "Unrecognized line " + str(l) + ": " + line
                    pass

                # BULLOCKS: some properties are not listed in the log. Seems like the flow properties are missing

                #Estimator.check_stable_Time at estimator.ads:65 flow analyzed (0 errors and 0 warnings) and not proved, 15 checks out of 16 proved
                #Estimator.get_Baro_Height at estimator.ads:52 flow analyzed (0 errors and 0 warnings) and proved (0 checks)

        if unit: units[unit]=unitinfo
        return units
    else: #except:
        print "ERROR reading file " + inputfile
        return None

def get_totals(reportunits, buildunits):    
    if not reportunits: return None

    # coverage from report
    total_cov = 0.0
    total_proven = 0.0
    total_props = 0
    total_subs = 0
    for u,uinfo in reportunits.iteritems():
        if uinfo["subs"] == 0:
            cov = 100
            subs = 0
        else:
            cov = 100 * (1.0 - uinfo["skip"] / uinfo["subs"])
            subs = uinfo["subs"]
        
        proven= uinfo["proven"]
        props = uinfo["props"]
        total_subs = total_subs + subs
        total_cov = total_cov + cov
        total_proven = total_proven + proven
        total_props = total_props + props

    if buildunits:
        # percentage proven and total number from build log
        total = sum([v["props"] for k,v in buildunits.iteritems()])
        proven_percent = 0
        if total > 0:
            proven = sum([v["proven"] for k,v in buildunits.iteritems()])
            proven_percent = 100*(float(proven) / total)
    else:
        total = total_props # underestimate!
        proven_percent = 100*(total_proven / total)

    num_units = len(reportunits)
    totals = {"units" : num_units, "coverage" : total_cov / num_units, "props" : total, "proven" : proven_percent, "subs": total_subs}
    return totals
    
def print_usage():
    print __file__ + " [OPTION] <gnatprove.out> [<build.log>]"
    print ''
    print 'OPTIONS:'
    print '    none so far'
    # print '  -p, --precision: '
    # print '         set the required precision of the WCET estimate'
    # print '         in units of processor cycles. Default: 0.'
    # print '  -m, --max-steps: '
    # print '         set the maximum number of iteration steps.'
    # print '         Default: infinite.'
    # print '  -c, --collect: '
    # print '         Collect all counterexamples in one XML file'
    # print '  -g, --guess:  (!!! Experimental !!!)'
    # print '         Start with the initial assumption that WCET is <= given value.'
    # print '         Default: UINT_MAX'
    # print ' '

def main(argv):
    inputfile = None
    buildlogfile = None

    try:
        opts, args = getopt.getopt(argv, "h", ["help"])
    except getopt.GetoptError:
        print_usage();
        sys.exit(2)

    if len(sys.argv) < 2:
        print_usage();
        sys.exit(0);

    for opt, arg in opts:
        if opt in ('-h', "--help"):
            print_usage()
            sys.exit()

    inputfile = args[0]
    if len(args) > 1: buildlogfile = args[1]

    print "report file: " + inputfile                
    reportunits = get_report_stats(inputfile=inputfile)
    if not reportunits: return 1
    pprint.pprint (reportunits)

    if buildlogfile:
        print "build log file: " + buildlogfile
        buildunits = get_stdout_stats(inputfile=buildlogfile)
        if not buildunits: return 1
        pprint.pprint (buildunits)
    else:
        buildunits = None    
        
    totals = get_totals(reportunits, buildunits)
    if not totals: return 2
    print "TOTALS: " + str(totals)
    
    return 0

if __name__ == "__main__":
    main(sys.argv[1:])


