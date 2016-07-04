#!/usr/bin/env python

"""This file implements the tools for managing requirements

(C) 2016 by Martin Becker <becker@rcs.ei.tum.de>

"""

import sys
import os
import os.path
import sqlite3

__author__ = "Martin Becker"
__copyright__ = "Copyright 2016, Martin Becker"
__license__ = "GPL"
__version__ = "1.0.0"
__email__ = "becker@rcs.ei.tum.de"
__status__ = "Testing"

DBFILE="requirements.db"

class Database:
    """
    implements the access (read/write) to the requirements database
    """

    _conn = None
    
    def __init__(self):
        pass

    def exists(self, filename):
        return os.path.isfile(filename)
    
    def create(self, filename="requirements.db"):
        # 1. create file only if not existing
        flags = os.O_CREAT | os.O_EXCL | os.O_WRONLY
        try:
            file_handle = os.open(filename, flags)
        except OSError as e:
            if e.errno == errno.EEXIST:  # Failed as the file already exists.
                return
            else:
                raise
        # No exception, so the file must have been created successfully.
        
        # 2. now create table
        cmd = """
        CREATE TABLE requirements (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               name VARCHAR(255),
               description TEXT,
               verification TEXT,
               date_added DATETIME);
        """
        c = conn.cursor()
        try:
            c.execute(cmd)
        except:
            print "ERROR creating database"
        else:
            conn.commit()
    
    def connect(self,filename):
        print "DB connect (" + filename + ")"
        self._conn = sqlite3.connect(filename)
        if not self._conn:
            print "ERROR opening DB " + filename

    def disconnect(self):
        print "DB close"
        self._conn.close()
    
    def get_requirements(filter=None):
        print "get req..."
        # TODO: dump all

    def __enter__(self):
        """CTOR"""
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        """DTOR"""
        try:
            self.disconnect()
        except:
            pass
        
def test():
    print "This module is not standalone."

if __name__ == "__main__":
    test()
