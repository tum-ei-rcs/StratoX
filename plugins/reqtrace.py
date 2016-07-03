"""This file provides support for tracing of low-level requirements
to source code and vice versa.

To use it, annotate subprograms in comments like follows:

    -- @req bar
    procedure foo;

    -- @req foo-fun/1
    procedure foo is
    begin
       null; -- @req blabla
    end foo;

This will link the requirements "foo-fun/1", "bar", and "blabla" from the
database with the procedure foo. For evaluation of coverage and tracing,
use the menu item "requirements".

TODO: read SPARK annotations and export them as verification means.

(C) 2016 by Martin Becker <becker@rcs.ei.tum.de>

"""


############################################################################
# No user customization below this line
############################################################################

import GPS
import sys
import os.path
import re
import gps_utils
from constructs import *
import text_utils

MENUITEMS = """
<submenu before="Window">
      <Title>Requirements</Title>
        <menu action="List Subprogram Requirements">
          <Title>List requirements implemented by subprogram</Title>
        </menu>
        <menu><title/></menu>
        <menu action="List Open Requirements">
          <Title>Show open requirements</Title>
        </menu>
        <menu action="Mark Unjustified Code">
          <Title>Mark unjustified code</Title>
        </menu>
        <menu action="Check Density">
        <title>Check Density of Requirements</title>
        </menu>
        <menu><title/></menu>
        <menu action="List All Requirements">
          <Title>Show all requirements</Title>
        </menu>
</submenu>
<action name="Some Other Action">
    <shell lang="python">print 'a'</shell>
</action>
"""


class Reqtrace(object):

    def __init__(self):
        """
        Various initializations done before the gps_started hook
        """

        self.port_pref = GPS.Preference("Plugins/reqtrace/port")
        self.port_pref.create(
            "Pydoc port", "integer",
            """Port that should be used when spawning the pydoc daemon.
This is a small local server to which your web browser connects to display the
documentation for the standard python library. It is accessed through the
/Python menu when editing a python file""",
            9432)

        XML = """
        <documentation_file>
           <name>http://docs.python.org/2/tutorial/</name>
           <descr>Requirements Tracer tutorial</descr>
           <menu>/Help/Requirements/Tutorial</menu>
           <category>Scripts</category>
        </documentation_file>
        <documentation_file>
          <shell lang="python">"""

        XML += """GPS.execute_action('display reqtrace help')</shell>
          <descr>Requirements Tracer</descr>
          <menu>/Help/Requirements/Help</menu>
          <category>Scripts</category>
        </documentation_file>
        """

        XML += MENUITEMS;

        GPS.parse_xml(XML)

    def gps_started(self):
        """
        Initializations done after the gps_started hook (add menu)
        """

        # declare local function as action (menu, shortcut, etc.)
        gps_utils.make_interactive(
            callback=self.mark_unjustified_code,
            name='Mark Unjustified Code')

        gps_utils.make_interactive(
            callback=self.check_density,
            name='Check Density')

        # declare local function as action (menu, shortcut, etc.)
        gps_utils.make_interactive(
            callback=self.list_subp_requirements,
            name='List Subprogram Requirements')

        # context menu in editor
        #gps_utils.make_interactive(
        #    callback=self.reload_file,
        #    name='MBe reload requirements',
        #    contextual='Requirements/Reload')

        GPS.Hook("project_view_changed").add(self._project_recomputed)
        GPS.Hook("before_exit_action_hook").add(self._before_exit)

    def check_density(self):
        """
        Count the number of SLOC per requirements and warn if density is
        too low. We are targeting at most 20SLOC/requirement
        """
        print "not implemented, yet"

    def mark_unjustified_code(self):
        """
        iterate over all files and subprograms and warn if a subprogram has no requirements
        """
        print ""

        # FIXME: we must make sure that gnatinspect.db is up-to-date. How? Rebuilding helps.

        # get current cursor
        ctx = GPS.current_context()
        curloc = ctx.location()
        file = curloc.file()
        editor = GPS.EditorBuffer.get(file)

        #try:
        #    GPS.Editor.unhighlight(str(file), "Unjustified_Code");
        #except:
        #    pass
        GPS.Locations.remove_category("Unjustified_Code");
        GPS.Editor.register_highlighting("Unjustified_Code", "#F9E79F")

        # iterate over all subprograms (requires cross-referencing to work)
        for ent,loc in file.references(kind='body'):
            if ent.is_subprogram():
                print "entity: " + ent.name() + " at " + str(loc)
                # extract requirements for the entity
                if editor is not None:
                    edloc = editor.at(loc.line(), loc.column())
                    #(startloc, endloc) = self._get_enclosing_block(edloc)
                    (name,reqs) = self._get_subp_requirements (editor, loc)
                    # name should equal ent.name
                    if (name.strip() != ent.name().strip()):
                        print "Warning: GPS Entity name '" + ent.name() + "' differs from found entity '" + name + "'"
                    if not reqs:
                        print "Entity '" + name + "' has ZERO requirements"
                        GPS.Locations.add(category="Unjustified_Code",
                                  file=file,
                                  line=loc.line(),
                                  column=loc.column(),
                                  message="no requirements for '" + name + "'",
                                  highlight="Unjustified_Code")
                    else:
                        rnames = [k for k,v in reqs.iteritems()]
                        print "Entity '" + name + "' has " + str(len(reqs)) + " requirements: " + str(rnames)


    def _extract_comments(self, sourcecode, linestart, filename):
        """
        returns only the comments of ada source code.
        list of dict ("text" : <comment text>, "file": <path>, "line" : <int>, "col", <int>)
        """

        comment = []
        l = linestart
        for line in sourcecode.splitlines():
            pos = line.find("--")
            if pos >=0:
                comment.append({"text" : line[pos+2:], "file": filename, "line" : l, "col" : pos + 2})
            l = l + 1
        return comment

    def _extract_requirements(self, comment):
        """
        parse comments and return the referenced requirements
        """
        reqs = {}

        pattern = re.compile("@req (\S+)")
        for c in comment:
            results = re.finditer(pattern, c["text"])
            for match in results:
                colstart = match.start(0) + c["col"] + 1
                reqname = match.group(1)
                if not reqname in reqs:
                    reqs[match.group(1)] = [];
                reqs[match.group(1)].append({"file" : c["file"], "line" : c["line"], "col" : colstart});

        # TODO: postprocessing. ACtually check whether requirements exist in database, otherwise mark them as invalid

        return reqs

    def _get_subp_requirements(self, editor, fileloc):
        """
        from given location find subprogram entity, and then check both its body and spec for requirements
        return: name of subp, dict of requirements
        """
        # 1. get entity belonging to cursor
        (entity, loccodestart, loccodeend) = self._get_enclosing_entity(fileloc)
        if not entity:
            print "No enclosing entity found"
            return None, None

        name = entity.name()

        # extract requirements from the range
        editor = GPS.EditorBuffer.get(fileloc.file())
        reqs = self._get_requirements_in_range (editor, loccodestart, loccodeend)

        # 2. find the counterpart (spec <=> body) and also look there
        try:
            locbody = entity.body()
        except:
            locbody = None
        try:
            locspec = entity.declaration()
        except:
            locspec = None
        is_body = locbody and locbody.line() == loccodestart.line()

        reqs_other = None
        if is_body and locspec:
            editor = GPS.EditorBuffer.get(locspec.file())
            (entity, loccodestart, loccodeend) = self._get_enclosing_entity(locspec)
            reqs_other = self._get_requirements_in_range (editor, loccodestart, loccodeend)
        if not is_body and locbody:
            editor = GPS.EditorBuffer.get(locbody.file())
            (entity, loccodestart, loccodeend) = self._get_enclosing_entity(locbody)
            reqs_other = self._get_requirements_in_range (editor, loccodestart, loccodeend)

        # merge dicts
        if reqs_other:
            for k,v in reqs_other.iteritems():
                if not k in reqs:
                    reqs[k] = v
                else:
                    reqs[k].append(v)

        # all done
        return name, reqs

    def _get_requirements_in_range(self, editor, locstart0, locend0):
        (locstart, locend) = self._widen_withcomments(locstart0, locend0)
        if locstart is None or locend is None:
            print "Error getting subprogram range"
            return None

        # now extract all comments from range
        sourcecode = self._get_buffertext(editor,locstart,locend)
        # print "src=" + str(sourcecode)
        comments = self._extract_comments(sourcecode,locstart.line(), str(locstart.buffer().file()))
        return self._extract_requirements(comments)

    def _show_locations(self,reqs):
        """
        show requirements in location window
        """
        if not reqs:
            return

        GPS.Editor.register_highlighting("My_Category", "#D5F5E3")
        for req,refs in reqs.iteritems():
            for ref in refs: # each requirement can have multiple references
                print "file=" + ref["file"]
                GPS.Locations.add(category="Requirements",
                                  file=GPS.File(ref["file"]),
                                  line=ref["line"],
                                  column=ref["col"],
                                  message=req,
                                  highlight="My_Category")


    def list_subp_requirements(self):
        print ""

        # get current cursor
        ctx = GPS.current_context()
        curloc = ctx.location()
        editor = GPS.EditorBuffer.get(curloc.file())

        (name, reqs) = self._get_subp_requirements (editor, curloc)
        if reqs:
            self._show_locations(reqs)
            print "Requirements in '" + name + "':"
            for k,v in reqs.iteritems():
                print " - " + k + ": " + str(v)
        else:
            print "No requirements referenced in '" + name + "'"

    def _project_recomputed(self, hook_name):
        """
        if python is one of the supported language for the project, add various
        predefined directories that may contain python files, so that shift-F3
        works to open these files as it does for the Ada runtime
        """

        GPS.Project.add_predefined_paths(
            sources="%splug-ins" % GPS.get_home_dir())
        try:
            GPS.Project.root().languages(recursive=True).index("python")
            # The rest is done only if we support python
            GPS.Project.add_predefined_paths(sources=os.pathsep.join(sys.path))
        except:
            pass

    def _get_enclosing_block(self, cursor):
        blocks = {"CAT_PROCEDURE": 1, "CAT_FUNCTION": 1, "CAT_ENTRY": 1,
                    "CAT_PROTECTED": 1, "CAT_TASK": 1, "CAT_PACKAGE": 1}

        if cursor.block_type() == "CAT_UNKNOWN":
            return None, None

        min = cursor.buffer().beginning_of_buffer()
        max = cursor.buffer().end_of_buffer()
        while not (cursor.block_type() in blocks) and cursor > min:
            cursor = cursor.block_start() - 1

        if cursor <= min:
            return None, None

        codestart = cursor.block_start() # gives a cursor
        codeend = cursor.block_end()
        return codestart, codeend

    def _widen_withcomments(self, codestart, codeend):
        """
        Widens the given bounds to include directly
        preceeding and succeeding comments
        """

        min = codestart.buffer().beginning_of_buffer()
        max = codestart.buffer().end_of_buffer()

        # look for comments lines directly before and after block and widen cursors accordingly
        for dir in [-1, 1]:
            if dir == -1:
                doccursor = codestart
                boundary = min
            else:
                doccursor = codeend
                boundary = max
            lastvalid = doccursor
            while True:
                if doccursor == boundary:
                    break
                doccursor = doccursor.forward_line(dir)
                line = codestart.buffer().get_chars(doccursor.beginning_of_line(), doccursor.end_of_line())
                iscomment = line.strip().startswith("--")
                if not iscomment:
                    break
                else:
                    lastvalid = doccursor
            # apply the widened bound
            if dir == -1:
                codestart = lastvalid
            else:
                codeend = lastvalid
        return codestart, codeend

    def _get_buffertext(self, e, beginning, end):
        """
        Return the contents of a buffer between two locations
        """
        txt=""
        if beginning.line() != end.line():
            for i in range(beginning.line(), end.line()+1):
                if i == beginning.line:
                    col0 = beginning.col()
                else:
                    col0 = 1
                txt = txt + e.get_chars(e.at(i, col0), e.at(i, 1).end_of_line())
        else:
            txt = e.get_chars(end.beginning_of_line(), end.end_of_line())
        return txt

    def _get_enclosing_entity(self, curloc):
        """
        Return the entity that encloses the current cursor
        """

        buf = GPS.EditorBuffer.get(curloc.file(), open=False)
        if buf is not None:
            edloc = buf.at(curloc.line(), curloc.column())
            (start_loc, end_loc) = self._get_enclosing_block(edloc)
        else:
            return None, None, None

        if not start_loc:
            return None, None, None
        name = edloc.subprogram_name() # FIXME: not right.

        # [entity_bounds] returns the beginning of the col/line of the
        # definition/declaration. To be able to call GPS.Entity, we need to be
        # closer to the actual subprogram name. We get closer by skipping the
        # keyword that introduces the subprogram (procedure/function/entry etc.)

        id_loc = start_loc
        id_loc = id_loc.forward_word(1)
        try:
            return GPS.Entity(name, id_loc.buffer().file(),id_loc.line(), id_loc.column()), start_loc, end_loc
        except:
            return None, None, None

    def show_python_library(self):
        """Open a navigator to show the help on the python library"""
        base = port = self.port_pref.get()
        if not self.pydoc_proc:
            while port - base < 10:
                self.pydoc_proc = GPS.Process("pydoc -p %s" % port)
                out = self.pydoc_proc.expect(
                    "pydoc server ready|Address already in use", 10000)
                try:
                    out.rindex(   # raise exception if not found
                        "Address already in use")
                    port += 1
                except Exception:
                    break

        GPS.HTML.browse("http://localhost:%s/" % port)

    def _before_exit(self, hook_name):
        """Called before GPS exits"""
        return 1


# Create the class once GPS is started, so that the filter is created
# immediately when parsing XML, and we can create our actions.
module = Reqtrace()
GPS.Hook("gps_started").add(lambda h: module.gps_started())
