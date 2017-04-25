#!/usr/bin/python

# This script parses GNATprove's JSON output and gives per-unit verification
# statistics, as well as overall statistics. Supersedes gnatprove_filestats.py
#
# (C) 2017 TU Muenchen, RCS, Martin Becker <becker@rcs.ei.tum.de>

import sys, getopt, os, inspect, time, math, re, datetime, numpy, glob, pprint
import json, operator, subprocess, copy

# use this if you want to include modules from a subfolder
cmd_subfolder = os.path.realpath(os.path.abspath(os.path.join(os.path.split(inspect.getfile( inspect.currentframe() ))[0],"pytexttable")))
if cmd_subfolder not in sys.path:
    sys.path.insert(0, cmd_subfolder)
import texttable

#######################################
#     GLOBAL CONSTANTS
#######################################
GNATINSPECT="gnatinspect"
KNOWN_SORT_CRITERIA = ('alpha', 'coverage', 'success', 'props', 'ents', 'skip');

#######################################
#     GLOBAL VARIABLES
#######################################
# used to suppress output from subprocesses
FNULL = open(os.devnull, 'w')

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
            filebase = os.path.splitext(os.path.basename(filename))[0]
            unit = prefix + file2unit(filebase)
            try:
                with open(filename) as f:
                    contents = json.load(f)
            except:
                contents = {}

            # we get three sections:
            # 1) "spark" : that gives us the coverage. list of dicts.
            #              each item has {"spark": <all|spec|no>, "name" : <name>, "sloc" : [{"file": .., "line": ..}]}.
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
            d[unit]["filebase"] = filebase
    return d


def add_unitentities(jsondata, prjfile, folders):
    """
    For all units in the project, get list of entities.

    We wanted to use gnatinspect, but it does not give us what we need. We would have to
    give all included project files to it, since flag --runtime does not work as intended.
    Probably we should handover -Pp1.gpr,p2.gpr,... to this script, and then let 
    gprbuild or someone figure out object dirs. Then we could use the gpr files here

    For now, we parse the ALI files, which are in our main project's object dir. Advantage
    is, that there we find also the ALI files of included projects.
    """

    def get_entities_of_unit(filebase):
        """
        compile a list of entities in this unit

        Not perfect, either. When a generic package is instantiated, then all functions which are not 
        public are in the ALI file of the instantiating unit, but those with spec are not.

        """
        # def get_gnatinspect_result(filename):
        #     """
        #     Query entities of single file. This only works when the project actually contains the file
        #     without indirections.
        #     """
        #     global GNATINSPECT
        #     cmd = GNATINSPECT + " -P" + prjfile + ' --command="entities ' + filename + '"'
        #     print "cmd=" + cmd
        #     success = True
        #     try:
        #         ret = subprocess.check_output(cmd, stdin=FNULL, stderr=FNULL, shell=True)
        #     except subprocess.CalledProcessError as e:
        #         ret = e.output
        #         success = False
            
        #     print "success=" + str(success) + ", ret=" + str(ret)

        #     # TODO: turn ret into a dict
        #     d=ret
        #     return d

        # # first spec file
        # ents_spec = get_gnatinspect_result(filebase + ".ads")
        # print "ents in spec of " + unit["filebase"] + "=" + str(ents_spec)
        
        # # then body file
        # ents_body = get_gnatinspect_result(filebase + ".adb")

        def parse_ali_file(filebase):
            """
            Pull entities from ALI file
            """
            def decode_type(t):
                """
                verbose type from ALI symbol. See lib-xref.ads
                Only handles those with would appear in *.spark files
                
                Bodies of functions will not appear in SPARK, only specs.
                Task types will not appear in SPARK, only objects
                packages will appear
                """
                typ = None
                if t == 'K':
                    typ = "package" # used also for generic instances
                #elif t == 'T':
                #    typ = "task type"
                elif t == 't':
                    typ = "task object"
                #elif t == 'W':
                #    typ = "protected type"
                #elif t == 'w':
                #    typ = 'protected object'
                #elif t == ' ':
                #    typ = "subprogram type"
                elif t == 'V':
                    typ = "function"
                #elif t == 'v':
                #    typ = "generic function" # becomes a function where used, does not appear in SPARK file
                elif t == 'U':
                    typ = 'procedure'
                #elif t == 'u':
                #    typ = "generic procedure" # same here
                elif t == 'y':
                    typ = "abstract function"
                elif t == 'x':
                    typ = "abstract procedure"
                return typ
            
            d=[]
            notfound = True
            files = [fld + os.sep + filebase + ".ali" for fld in folders]
            active = False
            spec = False
            body = False
            for fi in files:
                try:
                    with open (fi) as f:                        
                        for line in f:
                            match = re.search(r"^X \d+ ([^\s]+)\.(ads|adb)", line)
                            if match:
                                active = True if match.group(1) == filebase else False
                                ext = match.group(2)
                                spec = True if match.group(2) == "ads" else False
                                body = True if match.group(2) == "adb" else False
                                continue
                            
                            if active:
                                # line type col level entity
                                if spec and not body:
                                    where = "ads"
                                elif body and not spec:
                                    where = "adb"
                                else:
                                    where = "unknown"
                                match = re.search(r"^(\d+)(\w)(\d+).(\w+)", line)
                                if match:
                                    ent_line = int (match.group(1))
                                    ent_type = decode_type (match.group(2))
                                    ent_col = int (match.group(3))
                                    ent_id = match.group(4)
                                    filename = filebase + "." + where
                                    if ent_type:
                                        #print ent_id + " @" + str(ent_line) + ", type=" + ent_type
                                        d.append({'name':ent_id, 'file':filename, 'line':ent_line, 'col':ent_col, 'type': ent_type, 'type_orig':match.group(2)})

                    notfound = False
                    break                
                except:
                    pass
            if notfound:
                print "WARNING: " + filebase + ".ali nowhere found"
                pass
            return d
        
        # parse ALI file
        ents = parse_ali_file (filebase)
        return ents

    json_with_ent = copy.copy(jsondata)
    for u,uinfo in jsondata.iteritems():
        json_with_ent[u]["entities"] = get_entities_of_unit (uinfo["filebase"])
    #pprint.pprint(json_with_ent["helper"])
    #exit(42)
    return json_with_ent

def get_statistics(jsondata, sorting, exclude, include, details):
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
        n_spark = 0 # entities total (including specs
        n_ent = len(uinfo['entities'])
        if "spark" in uinfo:
            for sub in uinfo["spark"]:
                is_package = True if sub["name"].lower() == u.lower() else False
                is_covered = True if sub["spark"] == "all" else False
                is_spec = True if sub["spark"] == "spec" else False
                if is_covered: c = c + 1
                if is_spec: s = s + 1 # that is half-way covered
                n_spark = n_spark + 1
        if not (n_spark <= n_ent):
            print "WARNING: Total number of entities in ALI file (" + str(n_ent) + ") is less than number of entities found by GNATprove (" + str(n_spark) + "); please check: " + u
            #pprint.pprint (uinfo)
            #exit(42)
            n_ent = n_spark
        abstract_units[u]={}
        abstract_units[u]["ents"] = n_ent
        abstract_units[u]["spec"] = s
        abstract_units[u]["body"] = c
        abstract_units[u]["skip"] = n_ent - c - s
        abstract_units[u]["coverage"] = (100*float(c) / n_ent) if n_ent > 0 else 0
        abstract_units[u]["coverage_spec"] = (100*float(c+s) / n_ent) if n_ent > 0 else 0

        # ents: number of entities
        # spec: number of entities where spec is in SPARK
        # body: number of entities where body is in SPARK
        # skip: number of entities where SPARK is off
        # coverage: number of entities where body in in SPARK divided by number of entities
        # coverage_spec: number of entities where at least spec in in SPARK divided by number of entities
        
        # GET SUCCESS of PROOF
        rule_stats={}
        p = 0
        ig = 0
        n = 0
        if "proof" in uinfo:
            n = len(uinfo["proof"])
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
                    lid = { k:v for k,v in proof.iteritems() if k in ('file','line','col','rule','severity','how_proved','check_tree')}
                    abstract_units[u].setdefault("details_proofs",[]).append(lid)
                
        abstract_units[u]["props"] = n
        abstract_units[u]["rules"] = rule_stats
        abstract_units[u]["proven"] = p
        abstract_units[u]["success"] = (100*float(p) / n) if n > 0 else 100.0
        abstract_units[u]["suppressed"] = ig

        # GET SUCCESS of FLOW
        rule_stats={}
        f = 0
        ig = 0
        if "flow" in uinfo:
            n = len(uinfo["flow"])
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

        abstract_units[u]["flows"] = n
        abstract_units[u]["flows_proven"] = f
        abstract_units[u]["flows_suppressed"] = ig
        abstract_units[u]["flows_success"] = (100*float(f) / n) if n > 0 else 100.0

        # carry over entities
        if details:
            abstract_units[u]["entities"] = uinfo["entities"]
        
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
    if exclude and not include:
		# filter away partial matches
        tmp = abstract_units
        abstract_units = {u: uinfo for u,uinfo in tmp.iteritems() if not any(substring in u for substring in exclude) }
    elif include and not exclude:
		# only keep perfect matches
		tmp = abstract_units
		abstract_units = {u: uinfo for u,uinfo in tmp.iteritems() if u in include }

        
    ##########
    # TOTALS
    ##########
    # ent_cov: number of entities with body in spark divided number of entities
    # ent_cov_spec: number of entities with at least spec in spark divided number of entities
    # unit_cov: deprecated. unweighted average of individual unit coverages. but unweighted is unfair.
    totals={}
    totals["units"] = len(abstract_units)
    totals["ents"] = sum([v["ents"] for k,v in abstract_units.iteritems()])
    totals["props"] = sum([v["props"] for k,v in abstract_units.iteritems()])
    totals["suppressed"] = sum([v["suppressed"] for k,v in abstract_units.iteritems()])
    totals["proven"] = sum([v["proven"] for k,v in abstract_units.iteritems()])
    totals["spec"] = sum([v["spec"] for k,v in abstract_units.iteritems()])
    totals["skip"] = sum([v["skip"] for k,v in abstract_units.iteritems()])
    #totals["unit_cov"] = (sum([v["coverage"] for k,v in abstract_units.iteritems()]) / totals["units"]) if totals["units"] > 0 else 0
    totals["ent_cov"] = (100*(float(totals["ents"] - totals["skip"] - totals["spec"])) / totals["ents"]) if totals["ents"] > 0 else 0
    totals["ent_cov_spec"] = (100*(float(totals["ents"] - totals["skip"])) / totals["ents"]) if totals["ents"] > 0 else 0
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
                total_rules[r]=dict(stat) # deep copy of entire rule
            else:
                # rule exists. accumulate individual keys
                for k,v in stat.iteritems():
                    if not k in total_rules[r]: # k=cnt,proven,...
                        total_rules[r][k]= v # copy
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
    Makes a nice ascii table from the units dict, only using keys=filtercols
    """
    if len (units) == 0: return
    tab = texttable.Texttable()
    tab.set_deco(texttable.Texttable.HEADER)
    tab.set_precision(1)

    # first row is header
    firstrowvalue = units[0].itervalues().next()
    header = ["unit"] + [k for k in firstrowvalue.iterkeys() if k in filtercols]

    num_datacols = (len(header)-1)
    alignment = ["l"] + ["r"] * num_datacols
    tab.set_cols_align(alignment);

    data = [header]
    maxlen = 0
    for u in units:
        u,uinfo = u.iteritems().next()
        if len(u) > maxlen: maxlen = len(u)
        fields = [v for k,v in uinfo.iteritems() if k in filtercols]
        data.append([u] + fields)
    tab.add_rows(data)
    tab.set_cols_width([maxlen] + [8]*num_datacols)

    print tab.draw()

def print_usage():
    print __file__ + " -P<gprfile>  [OPTION] (<gnatprove folder>)+"
    print ''
    print 'OPTIONS:'
    print '   --sort=s[,s]*'
    print '          sort statistics by criteria (s=' + ",".join(KNOWN_SORT_CRITERIA) + ')'
    print '          e.g., "--sort=coverage,success" to sort by coverage, then by success'
    print '   --table, -t'
    print '          print as human-readable table instead of JSON/dict'
    print '   --exclude=s[,s]*'
    print '          exclude units which contain any of the given strings'
    print '   --include=s[,s]*'
    print '          only include units which match exactly any of given strings'    
    print '   --details, -d'
    print '          keep detailed proof/flow information for each unit'

def main(argv):
    gfolders = []
    sorting = []
    exclude = []
    include = []
    table = False
    details = False
    prjfile = None

    try:
        opts, args = getopt.getopt(argv, "hs:te:i:dP:", ["help","sort=","table","exclude=","include=","details","project"])
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

        elif opt in ('-P', "--project"):
            prjfile=arg
            
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

        elif opt in ('-i', "--include"):
            cands = arg.split(",")
            for c in cands:
                s = c.strip()
                include.append(s)

        elif opt in ('-t', '--table'):
            table = True

        elif opt in ('-d', '--details'):
            details = True

    # not required at the moment
    # if not prjfile:
    #     print "ERROR: project file must be specified with flag -P"
    #     exit (1)
            
	if include and exclude:
		print "WARNING: cannot include and exclude the same time. Using exclude."
		include=[]
            
    if not sorting:
        sorting = KNOWN_SORT_CRITERIA
    print "sorting: " + ",".join(sorting)
    print "exclude: " + ",".join(exclude)
    print "include: " + ",".join(include)

    gfolders = args

    print "Using folders: " + str(gfolders)
    jsondata = get_json_data (gfolders)    
    if not jsondata: return 1

    jsondata = add_unitentities(jsondata, prjfile, gfolders)
    if not jsondata: return 1

    
    totals,abstract_units = get_statistics (jsondata, sorting=sorting, exclude=exclude, include=include, details=details)
    if not totals or not abstract_units: return 2
    #print abstract_units # all correct

    # print per unit
    if table:
        tablecols = ["unit","ents","success","coverage","coverage_spec","proven","props","flows","flows_success"]
        print_table (abstract_units, tablecols)        
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
