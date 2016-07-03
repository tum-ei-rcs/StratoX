"""This file provides support for tracing of low-level requirements
to source code and vice vesa.

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
        <menu action="List Open Requirements">
          <Title>Show open requirements</Title>
        </menu>
        <menu action="Mark Unjustified Code">
          <Title>Mark unjustified code</Title>
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

        # declare local function as action (menu, shortcut, etc.)
        gps_utils.make_interactive(
            callback=self.list_subp_requirements,
            name='List Subprogram Requirements')

        # context menu in editor
        gps_utils.make_interactive(
            callback=self.reload_file,
            name='MBe reload requirements',
            contextual='Requirements/Reload')

        GPS.Hook("project_view_changed").add(self._project_recomputed)
        GPS.Hook("before_exit_action_hook").add(self._before_exit)

    def mark_unjustified_code(self):
        print "Mark Unjustified Code"

    def extract_comments(self, sourcecode, linestart):
        """
        returns only the comments of ada source code.
        list of dict ("text", "line", "col")
        """

        comment = []
        l = linestart
        for line in sourcecode.splitlines():
            pos = line.find("--")
            if pos >=0:
                comment.append({"text" : line[pos+2:], "line" : l, "col" : pos + 2})
            l = l + 1
        return comment

    def extract_requirements(self, comment):
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
                reqs[match.group(1)].append({"line" : c["line"], "col" : colstart});

        return reqs

    def list_subp_requirements(self):
        print ""
        (name, locstart, locend) = self.compute_subp_range(GPS.current_context())
        if locstart is None or locend is None:
            print "Error getting subprogram range"
            return

        # now extract all comments from range
        editor = GPS.EditorBuffer.get()
        sourcecode = self.get_buffertext(editor,locstart,locend)
        comments = self.extract_comments(sourcecode,locstart.line())
        # TODO: also look in spec
        reqs = self.extract_requirements(comments)
        if reqs:
            print "Requirements in '" + name + "':"
            for k,v in reqs.iteritems():
                print " - " + k + ": " + str(v)
        else:
            print "No requirements referenced in '" + name + "'"

    def reload_file(self):
        """
        Reload the currently edited file in python.
        If the file has not been imported yet, import it initially.
        Otherwise, reload the current version of the file.
        """

        try:
            f = GPS.current_context().file()
            module = os.path.splitext(os.path.basename(f.name()))[0]

            # The actual import and reload must be done in the context of the
            # GPS console so that they are visible there. The current function
            # executes in a different context, and would not impact the GPS
            # console as a result otherwise.

            # We cannot use  execfile(...), since that would be the equivalent
            # of "from ... import *", not of "import ..."

            if module in sys.modules:
                GPS.exec_in_console("reload(sys.modules[\"" + module + "\"])")

            else:
                try:
                    sys.path.index(os.path.dirname(f.name()))
                except:
                    sys.path = [os.path.dirname(f.name())] + sys.path
                mod = __import__(module)

                # This would import in the current context, not what we want
                # exec (compile ("import " + module, "<cmdline>", "exec"))

                # The proper solution is to execute in the context of the GPS
                # console
                GPS.exec_in_console("import " + module)
        except:
            pass   # Current context is not a file

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

    def subprogram_bounds(self,cursor,withcomments=False):
        """
        Return the first and last line of the current subprogram, and (0,0) if
        the current subprogram could not be determined.
        """

        blocks = {"CAT_PROCEDURE": 1, "CAT_FUNCTION": 1, "CAT_ENTRY": 1,
                    "CAT_PROTECTED": 1, "CAT_TASK": 1, "CAT_PACKAGE": 1}

        if cursor.block_type() == "CAT_UNKNOWN":
            return None, None

        min = cursor.buffer().beginning_of_buffer()
        max = cursor.buffer().end_of_buffer()
        while not (cursor.block_type() in blocks) and cursor > min:
            cursor = cursor.block_start() - 1

        if cursor > min:
            codestart = cursor.block_start() # gives a cursor
            codeend = cursor.block_end()
            if withcomments:
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
                        line = doccursor.buffer().get_chars(doccursor.beginning_of_line(), doccursor.end_of_line())
                        iscomment = line.strip().startswith("--")
                        if not iscomment:
                            break
                        else:
                            lastvalid = doccursor
                    if dir == -1:
                        codestart = lastvalid
                    else:
                        codeend = lastvalid
                return codestart, codeend
        else:
            return None, None

    def get_buffertext(self, e, beginning, end):
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

    def compute_subp_range(self, ctx):
        """Return the source code range of subprogram that we are
        currently in, and also include directly preceeding and
        directly following comments
        """

        try:
            curloc = ctx.location()
            buf = GPS.EditorBuffer.get(curloc.file(), open=False)
            if buf is not None:
                edloc = buf.at(curloc.line(), curloc.column())
                (start_loc, end_loc) = self.subprogram_bounds(edloc, withcomments=True)
            else:
                return None
        except:
            return None

        if not start_loc:
            return None
        name = edloc.subprogram_name()

        # [subprogram_start] returns the beginning of the line of the
        # definition/declaration. To be able to call GPS.Entity, we need to be
        # closer to the actual subprogram name. We get closer by skipping the
        # keyword that introduces the subprogram (procedure/function/entry etc.)

#        start_loc = start_loc.forward_word(1)
#        try:
#            entity = GPS.Entity(name, start_loc.buffer().file(),
#                                start_loc.line(), start_loc.column())
#        except:
#            return None

#        if entity is not None:
        return (name, start_loc, end_loc) #entity.declaration()
#        else:
#            return None

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
