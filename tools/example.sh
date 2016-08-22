#!/bin/bash
./gnatprove_filestats.py --sort=coverage,success,props --table gnatprove.out build.log
