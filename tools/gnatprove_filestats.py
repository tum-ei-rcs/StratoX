#!/usr/bin/python

# This script parses GNATprove output and gives per-file coverage statistics,
# as well as overall statistics
#
# (C) 2016 TU Muenchen, RCS, Martin Becker <becker@rcs.ei.tum.de>

import sys, getopt, os, inspect, time, math, re, datetime, numpy;
import pprint;

# use this if you want to include modules from a subfolder
cmd_subfolder = os.path.realpath(os.path.abspath(os.path.join(os.path.split(inspect.getfile( inspect.currentframe() ))[0],"pytexttable")))
if cmd_subfolder not in sys.path:
    sys.path.insert(0, cmd_subfolder)
import texttable

#######################################
#     GLOBAL CONSTANTS
#######################################

KNOWN_SORT_CRITERIA = ('alpha', 'coverage', 'success', 'props', 'subs', 'skip');

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

def get_totals(reportunits, buildunits, sorting):
    if not reportunits: return None

    #################
    #  COMPLETE DATA
    #################
    
    ## DATA FROM REPORT
    for u,uinfo in reportunits.iteritems():
        if uinfo["subs"] > 0:
            unit_cov = 100 * (1.0 - (float(uinfo["skip"]) / uinfo["subs"]))
        else:
            unit_cov = 100
        if uinfo["props"] > 0:
            unit_success = 100*float(uinfo["proven"])/uinfo["props"]
        else:
            unit_success = 100
        reportunits[u]["success"] = unit_success
        reportunits[u]["coverage"] = unit_cov
        reportunits[u]["datasrc"] = "report"        


    ## DATA FROM BUILD LOG
    if buildunits:
        for u,uinfo in buildunits.iteritems():
            buildunits[u]["datasrc"] = "log"
            buildunits[u]["subs"]=0 # unknown
            buildunits[u]["coverage"] = 100 # unknown
            buildunits[u]["skip"] = 0 # unknown
            if uinfo["props"] > 0:
                unit_success = float(uinfo["proven"])/uinfo["props"]*100
            else:
                unit_success = 100.0
            buildunits[u]["success"] = unit_success

    #################
    #  MERGE DATA
    #################
    def do_merge(uinfo1, uinfo2):
        uinfo["datasrc"] = "merged"
        for cat in ("subs", "props", "proven", "skip"):
            uinfo[cat] = max(uinfo1[cat],uinfo2[cat])
        if uinfo["props"] > 0:
            uinfo["success"] = 100*float(uinfo["proven"]) / uinfo["props"]
        else:
            uinfo["success"] = 100.0
        if uinfo["subs"] > 0:
            uinfo["coverage"] = 100 * (1.0 - (float(uinfo["skip"]) / uinfo["subs"]))
        else:
            uinfo["coverage"] = 100.0
        return uinfo
    # ----------
    mergedunits=reportunits
    if buildunits:
        for u,uinfo in buildunits.iteritems():
            if u in mergedunits:
                mergedunits[u] = do_merge(mergedunits[u], uinfo)
            else:
                mergedunits[u] = uinfo
        
    ## TOTALS
    n = len(mergedunits)
    total_subs = sum([v["subs"] for k,v in mergedunits.iteritems()])
    total_props = sum([v["props"] for k,v in mergedunits.iteritems()])
    total_proven = sum([v["proven"] for k,v in mergedunits.iteritems()])
    total_cov = sum([v["coverage"] for k,v in mergedunits.iteritems()]) / n
    total_success = 100*(float(total_proven) / total_props)
    totals = {"units" : n, "coverage" : total_cov, "props" : total_props, "proven":total_proven, "success" : total_success, "subs": total_subs}
    
    #################
    #  SORT
    #################
    tmp = [{k : v} for k,v in mergedunits.iteritems()]
    def keyfunc(tup):
        key, d = tup.iteritems().next()
        tmp = [s for s in sorting if s != "alpha"]
        order = [d[t] for t in tmp]
        return order
    if "alpha" in sorting:
        sorted_mergedunits = sorted(tmp, key=lambda x: x)
    else:
        sorted_mergedunits = sorted(tmp, key=keyfunc, reverse=True)
        
    return totals, sorted_mergedunits

def print_table(units):
    if len (units) == 0: return
    tab = texttable.Texttable()    
    tab.set_deco(texttable.Texttable.HEADER)
    tab.set_precision(1)
    
    # first row is header
    firstrowvalue = units[0].itervalues().next()
    header = ["unit"] + [k for k in firstrowvalue.iterkeys()]
    
    num_datacols = (len(header)-1)
    alignment = ["l"] + ["r"] * num_datacols    
    tab.set_cols_align(alignment);

    data = [header]
    maxlen = 0
    for u in units:
        u,uinfo = u.iteritems().next()
        if len(u) > maxlen: maxlen = len(u)
        fields = [v for k,v in uinfo.iteritems()]
        data.append([u] + fields)
    tab.add_rows(data)
    tab.set_cols_width([maxlen] + [8]*num_datacols)
    
    print tab.draw()

def print_usage():
    print __file__ + " [OPTION] <gnatprove.out> [<build.log>]"
    print ''
    print 'OPTIONS:'
    print '   --sort=s[,s]*'
    print '          sort statistics by criteria (s=' + ",".join(KNOWN_SORT_CRITERIA) + ')'
    print '          e.g., "--sort=coverage,success" to sort by coverage, then by success'
    print '   --table, t'
    print '          print as human-readable table instead of JSON/dict' 

def main(argv):
    inputfile = None
    buildlogfile = None
    sorting = []
    table = False

    try:
        opts, args = getopt.getopt(argv, "hs:t", ["help","sort=","table"])
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
        elif opt in ('-s', "--sort"):
            cands = arg.split(",")
            for c in cands:
                s = c.strip()
                if s in KNOWN_SORT_CRITERIA:
                    sorting.append(s)
                else:
                    print "Sort criteria '" + s + "' unknown"
        elif opt in ('-t', '--table'):
            table = True

    if not sorting:
        sorting = KNOWN_SORT_CRITERIA
    print "sorting: " + ",".join(sorting)
                    
    inputfile = args[0]
    if len(args) > 1: buildlogfile = args[1]

    print "report file: " + inputfile                
    reportunits = get_report_stats(inputfile=inputfile)
    if not reportunits: return 1
    #pprint.pprint (reportunits)

    if buildlogfile:
        print "build log file: " + buildlogfile
        buildunits = get_stdout_stats(inputfile=buildlogfile)
        if not buildunits: return 1
        #pprint.pprint (buildunits)
    else:
        buildunits = None    
        
    totals,mergedunits = get_totals(reportunits, buildunits, sorting)
    if not totals or not mergedunits: return 2

    if not table:
        for m in mergedunits:
            u, uinfo = m.iteritems().next()
            print u + " : " + str(uinfo)
    else:
        print_table (mergedunits)
    print "TOTALS: " + str(totals)
    
    return 0

if __name__ == "__main__":
    main(sys.argv[1:])


