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

    def _exists(self, filename):
        return os.path.isfile(filename)
    
    def _create(self, filename="requirements.db"):
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
        self._conn = sqlite3.connect(filename)
        cmd = """
        CREATE TABLE requirements (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               name VARCHAR(255),
               description TEXT,
               verification TEXT,
               date_added DATETIME);
        """
        c = self._conn.cursor()
        try:
            c.execute(cmd)
        except:
            print "ERROR creating database"
        else:
            print "Created new DB"
            self.disconnect()
    
    def connect(self,filename):
        if not self._exists(filename):
            self._create(filename)
        
        self._conn = sqlite3.connect(filename)
        if not self._conn:
            print "ERROR opening DB " + filename

    def disconnect(self):
        try:
            self._conn.commit()
            self._conn.close()
        except:
            pass
    
    def get_requirements(self,filter=None):
        """
        return a dictionary with all requirements matching the filter.

        @param filter dict of regular expressions for the database fields TODO

        @return dict { reqname1 => { database_field1 : database_value1, databasefield2 : ...}, ...}
        """        
        if not self._conn:
            print "ERROR: not connected to DB"
            return {}

        c = self._conn.cursor()
        query = "SELECT * FROM requirements"
        if filter:
            fstring = [k + "=:" + k for k,v in filter.iteritems()]
            query = query + " WHERE " + fstring.join(" and ")
        query = query + ";"
            
        print "(Req DB query=" + query + ")"
        if filter:
            c.execute(query,fstring)
        else:
            c.execute(query)            
        headers = [t[0] for t in c.description]        
        results = c.fetchall()
        namepos = headers.index("name")
        if not namepos:
            print "DB error: field 'name' is missing"
            return {}
        retdict = { row[namepos] : { headers[idx] : value for idx,value in enumerate(row)} for row in results }
        return retdict

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
