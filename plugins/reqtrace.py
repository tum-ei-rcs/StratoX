"""This file provides support for tracing of low-level requirements
to source code and vice vesa.

(C) 2016 by Martin Becker <becker@rcs.ei.tum.de>

"""


############################################################################
# No user customization below this line
############################################################################

# To be added (from idle environment)
#   - "indent region", "dedent region", "check module", "run module"
#   - "class browser" -> project view in GPS

import GPS
import sys
import os.path
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
<action name="List Subprogram Requirements">
    <shell lang="python">print 'a'</shell>
</action>
"""

def get_last_body_statement(node):
    if hasattr(node, "body"):
        return get_last_body_statement(node.body[-1])
    else:
        return node

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

        # context menu in editor
        gps_utils.make_interactive(
            callback=self.reload_file,
            name='MBe reload requirements',
            contextual='Requirements/Reload')

        # by this we allow the user to use a keybinding
        gps_utils.make_interactive(
            callback=self.indent_on_new_line,
            name="Requirements Auto Indentation")

        GPS.Hook("project_view_changed").add(self._project_recomputed)
        GPS.Hook("before_exit_action_hook").add(self._before_exit)

    def mark_unjustified_code(self):
        print "mark_unjustified_code"

    def indent_on_new_line(self):
        """
        This action parse the code (if it's python) and move cursor to
        the desired indentation level.
        """
        editor = GPS.EditorBuffer.get()
        start = editor.selection_start()
        end = editor.selection_end()

        # if a block is selected, delete the block
        if start.line() != end.line() or start.column() != end.column():
            editor.delete(start, end)

        # place the cursor at the head of a new line
        editor.insert(start, "\n")


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
