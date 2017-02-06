#!/usr/bin/python

# This script parses GNATprove's JSON output and gives per-unit verification
# statistics, as well as overall statistics. Supersedes gnatprove_filestats.py
#
# (C) 2017 TU Muenchen, RCS, Martin Becker <becker@rcs.ei.tum.de>

import sys, getopt, os, inspect, time, math, re, datetime, numpy, glob, pprint
import json, operator

# use this if you want to include modules from a subfolder
cmd_subfolder = os.path.realpath(os.path.abspath(os.path.join(os.path.split(inspect.getfile( inspect.currentframe() ))[0],"pytexttable")))
if cmd_subfolder not in sys.path:
    sys.path.insert(0, cmd_subfolder)
import texttable

#######################################
#     GLOBAL CONSTANTS
#######################################

KNOWN_SORT_CRITERIA = ('alpha', 'coverage', 'success', 'props', 'ents', 'skip');

#######################################
#     FUNCTION DEFINITIONS
#######################################

def file2unit(filename):
    """
    transform file name into GNAT unit name
    """
    unitname = os.path.splitext(filename)[0]
    unitname = unitname.replace("-",".")
    return unitname.lower()

def get_json_data(folders):
    """
    Parses all *.spark files in the given directory and
    creates statistics for them
    """
    d={}
    for folder in folders:
        prefix = "" # file2unit(folder)
        if prefix: prefix = prefix + "."
        for filename in glob.glob(os.path.join(folder, '*.spark')):
            unit = prefix + file2unit(os.path.splitext(os.path.basename(filename))[0])
            try:
                with open(filename) as f:
                    contents = json.load(f)
            except:
                contents = {}

            # we get three sections:
            # 1) "spark" : that gives us the coverage. list of dicts.
            #              each item has {"spark": <all|spec>, "name" : <name>, "sloc" : [{"file": .., "line": ..}]}.
            #              If <name>=unit, then it's the package itself. Package with spark=spec means body not in SPARK mode
            #
            # 2) "flow" : flow analysis results. list of dicts.
            #             each item has {"file": .., "line": .., "col": .., "rule": .., "severity": .., "entity": {"name": .., "sloc": [{}]}, "tracefile": .., "msg_id": .., "how_proved": ..}
            #
            # 3) "proof" : prover results. list of dicts
            #             each item has the same as flow, but additionally {"cntexmp":{}, "suppressed" : <string>}. Here, rule=<VC_PRECONDITION|VC_DISCRIMINANT_CHECK|...>
            #
            # 4) "assumptions" : not interesting here. we remove it.
            #
            # Thus, coverage comes from "spark", success comes from "proof"

            try:
                contents.pop("assumptions", None)
            except:
                pass
            d[unit] = contents
    return d

def get_statistics(jsondata, sorting, exclude, details):
    """
    Turn the JSON data into an abstract summary.
    """

    #################
    # ABSTRACT DATA
    #################
    # we summarize the list of proofs into stats, and then keep only that
    abstract_units = {}
    for u,uinfo in jsondata.iteritems():
        # GET COVERAGE
        c = 0 # entities covered
        s = 0 # entities skipped (incl.
        n = 0 # entities total
        for sub in uinfo["spark"]:
            is_package = True if sub["name"].lower() == u.lower() else False
            is_covered = True if sub["spark"] == "all" else False
            is_spec = True if sub["spark"] == "spec" else False
            if not is_package:
                if is_covered: c = c + 1
                if is_spec: s = s + 1 # that is half-way covered
                n = n + 1
        abstract_units[u]={}
        abstract_units[u]["ents"] = n
        abstract_units[u]["spec"] = s
        abstract_units[u]["skip"] = n - c - s
        abstract_units[u]["coverage"] = (100*float(c) / n) if n > 0 else 0

        # GET SUCCESS of PROOF
        rule_stats={}
        p = 0
        ig = 0
        for proof in uinfo["proof"]:
            is_suppressed = True if "suppressed" in proof else False
            is_verified = True if proof["severity"]=="info" else (True if "suppressed" in proof else False)
            rule = proof["rule"]
            if is_verified: p = p + 1
            if is_suppressed : ig = ig + 1
            if not rule in rule_stats:
                rule_stats[rule]={"cnt": 0, "proven":0}
            rule_stats[rule]["cnt"] += 1
            rule_stats[rule]["proven"] += 1 if is_verified else 0            
            if details:
                lid = { k:v for k,v in proof.iteritems() if k in ('file','line','col','rule','severity')}
                abstract_units[u].setdefault("details_proofs",[]).append(lid)
                
        n = len(uinfo["proof"])
        abstract_units[u]["props"] = n
        abstract_units[u]["rules"] = rule_stats
        abstract_units[u]["proven"] = p
        abstract_units[u]["success"] = (100*float(p) / n) if n > 0 else 100.0
        abstract_units[u]["suppressed"] = ig

        # GET SUCCESS of FLOW
        rule_stats={}
        f = 0
        ig = 0
        for flow in uinfo["flow"]:
            is_suppressed = True if "suppressed" in flow else False
            is_verified = True if flow["severity"]=="info" else is_suppressed
            rule = flow["rule"]
            if is_verified: f = f + 1
            if is_suppressed : ig = ig + 1
            if not rule in rule_stats:
                rule_stats[rule]={"cnt": 0, "proven":0}
            rule_stats[rule]["cnt"] += 1
            rule_stats[rule]["proven"] += 1 if is_verified else 0
            if details:
                lid = { k:v for k,v in flow.iteritems() if k in ('file','line','col','rule','severity')}
                abstract_units[u].setdefault("details_flows",[]).append(lid)

        n = len(uinfo["flow"])
        abstract_units[u]["flows"] = n
        abstract_units[u]["flows_proven"] = f
        abstract_units[u]["flows_suppressed"] = ig
        abstract_units[u]["flows_success"] = (100*float(f) / n) if n > 0 else 100.0
        # merge rules
        for r,s in rule_stats.iteritems():
            if not r in abstract_units[u]["rules"]:
                abstract_units[u]["rules"][r] = s
            else:
                # merge
                for k,v in s.iteritems():
                    if not k in abstract_units[u]["rules"][r]:
                        abstract_units[u]["rules"][k]=v
                    else:
                        abstract_units[u]["rules"][k]+=v
        ###########
        # SORTING
        ###########        
        if "details_proofs" in abstract_units[u]:
            abstract_units[u]["details_proofs"].sort(key=operator.itemgetter('file','line','col','rule'))
        if "details_flows" in abstract_units[u]:
            abstract_units[u]["details_flows"].sort(key=operator.itemgetter('file','line','col','rule'))            


    ################
    # FILTER UNITS
    ################
    if exclude:
        tmp = abstract_units
        abstract_units = {u: uinfo for u,uinfo in tmp.iteritems() if not any(substring in u for substring in exclude) }


        
    ##########
    # TOTALS
    ##########
    totals={}
    totals["units"] = len(abstract_units)
    totals["ents"] = sum([v["ents"] for k,v in abstract_units.iteritems()])
    totals["props"] = sum([v["props"] for k,v in abstract_units.iteritems()])
    totals["suppressed"] = sum([v["suppressed"] for k,v in abstract_units.iteritems()])
    totals["proven"] = sum([v["proven"] for k,v in abstract_units.iteritems()])
    totals["skip"] = sum([v["skip"] for k,v in abstract_units.iteritems()])
    totals["unit_cov"] = (sum([v["coverage"] for k,v in abstract_units.iteritems()]) / totals["units"]) if totals["units"] > 0 else 0
    totals["ent_cov"] = (100*(float(totals["ents"] - totals["skip"])) / totals["ents"]) if totals["ents"] > 0 else 0
    totals["success"] = (100*(float(totals["proven"]) / totals["props"])) if totals["props"] > 0 else 0
    totals["flows"] = sum([v["flows"] for k,v in abstract_units.iteritems()])
    totals["flows_proven"] = sum([v["flows_proven"] for k,v in abstract_units.iteritems()])
    totals["flows_suppressed"] = sum([v["flows_suppressed"] for k,v in abstract_units.iteritems()])
    totals["flows_success"] = (100*(float(totals["flows_proven"]) / totals["flows"])) if totals["flows"] > 0 else 0
    # merge down rules (I know...ugly. But there is no faster and equally readable way)
    total_rules = {}
    for u,uinfo in abstract_units.iteritems():
        for r,stat in uinfo["rules"].iteritems():
            if not r in total_rules:
                total_rules[r]=stat
            else:
                # sum keys
                for k,v in stat.iteritems():
                    if not k in total_rules[r]:
                        total_rules[r][k]=v
                    else:
                        total_rules[r][k]+=v
    totals["rules"] = total_rules    

    #################
    #  SORT
    #################
    tmp = [{k : v} for k,v in abstract_units.iteritems()]
    def keyfunc(tup):
        key, d = tup.iteritems().next()
        tmp = [s for s in sorting if s != "alpha"]
        order = [d[t] for t in tmp]
        return order
    if "alpha" in sorting:
        sorted_abstract_units = sorted(tmp, key=lambda x: x)
    else:
        sorted_abstract_units = sorted(tmp, key=keyfunc, reverse=True)

    return totals, sorted_abstract_units

def print_table(units,filtercols):
    """
    Makes a nice ascii table from the units dict, while omitting keys=filtercols
    """
    if len (units) == 0: return
    tab = texttable.Texttable()
    tab.set_deco(texttable.Texttable.HEADER)
    tab.set_precision(1)

    # first row is header
    firstrowvalue = units[0].itervalues().next()
    header = ["unit"] + [k for k in firstrowvalue.iterkeys() if not k in filtercols]

    num_datacols = (len(header)-1)
    alignment = ["l"] + ["r"] * num_datacols
    tab.set_cols_align(alignment);

    data = [header]
    maxlen = 0
    for u in units:
        u,uinfo = u.iteritems().next()
        if len(u) > maxlen: maxlen = len(u)
        fields = [v for k,v in uinfo.iteritems() if not k in filtercols]
        data.append([u] + fields)
    tab.add_rows(data)
    tab.set_cols_width([maxlen] + [8]*num_datacols)

    print tab.draw()

def print_usage():
    print __file__ + " [OPTION] (<gnatprove folder>)+"
    print ''
    print 'OPTIONS:'
    print '   --sort=s[,s]*'
    print '          sort statistics by criteria (s=' + ",".join(KNOWN_SORT_CRITERIA) + ')'
    print '          e.g., "--sort=coverage,success" to sort by coverage, then by success'
    print '   --table, -t'
    print '          print as human-readable table instead of JSON/dict'
    print '   --exclude=s[,s]*'
    print '          exclude units which contain any of the given strings'
    print '   --details, -d'
    print '          keep detailed proof/flow information for each unit'

def main(argv):
    gfolders = []
    sorting = []
    exclude = []
    table = False
    details = False

    try:
        opts, args = getopt.getopt(argv, "hs:te:d", ["help","sort=","table","exclude=","details"])
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

        elif opt in ('-e', "--exclude"):
            cands = arg.split(",")
            for c in cands:
                s = c.strip()
                exclude.append(s)

        elif opt in ('-t', '--table'):
            table = True

        elif opt in ('-d', '--details'):
            details = True

            
    if not sorting:
        sorting = KNOWN_SORT_CRITERIA
    print "sorting: " + ",".join(sorting)
    print "exclude: " + ",".join(exclude)

    gfolders = args

    print "Using folders: " + str(gfolders)
    jsondata = get_json_data (gfolders)
    if not jsondata: return 1

    totals,abstract_units = get_statistics (jsondata, sorting=sorting, exclude=exclude, details=details)
    if not totals or not abstract_units: return 2

    # print per unit
    if table:
        filtercols = ["rules", "flows", "flows_suppressed", "flows_proven"]
        print_table (abstract_units, filtercols)        
    else:
        print json.dumps(abstract_units)

    # print totals
    print "TOTALS:"
    if table:
        pprint.pprint(totals)
    else:
        print json.dumps (totals)

    return 0

if __name__ == "__main__":
    main(sys.argv[1:])
