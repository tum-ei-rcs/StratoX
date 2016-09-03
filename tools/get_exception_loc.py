#!/usr/bin/python

#
# Given an address (of an exception), gets the function to which it belongs to. The
# address is not necessarily the beginning of the function, which is why we need
# this script

import sys, os, subprocess

FNULL = open(os.devnull, 'w')

def get_function(elf,addr):
    """
    query the function name
    """
    # arm-eabi-addr2line -e boot --functions --demangle 0x08049fae

    fname = subprocess.check_output("arm-eabi-addr2line -e " + elf + " --functions --demangle " + hex(addr),  stderr=FNULL, shell=True)

    return fname

def addr2dec(instr):
    """
    Turns a string holding either a hex or decimal address into a decimal number
    """
    addr = None

    try:
        addr = int(instr)
    except:
        pass    
    if addr: return addr

    try:
        addr = int(instr, 16);
    except:
        pass
    return addr

def print_usage():
    print __file__ + " [OPTION] <elf> <address>"
    print ''

    print "Usage:"
    print "  Provide the ELF file and an address of the exception in hex or decimal."
    print "  This script returns the function name it belongs to."

def main(argv):
    if len(sys.argv) < 3:
        print_usage()
        exit(1)

    elf = sys.argv[1]
    print "ELF=" + elf
    addr = addr2dec(sys.argv[2])
    if not addr:
        print "invalid address: " + sys.argv[2]
        exit (2)
    print "Address=" + str(addr)

    print get_function(elf,addr)
    exit(0)
        
if __name__ == "__main__":
    main(sys.argv[1:])
