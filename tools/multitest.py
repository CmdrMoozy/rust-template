#!/usr/bin/env python3
#
# This script executes "cargo test" for each combination of features this crate
# supports. This is used to find bugs which only present for certain feature
# combinations.

import itertools
import os
import subprocess
import sys

_DIRECTORY = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))

result = subprocess.run(['bash', '-c', 'cargo read-manifest | jq -r ".features | keys | .[]" | grep -v "^default$"'], cwd=_DIRECTORY, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
if result.returncode != 0:
    print(result.stdout)
    sys.exit(result.returncode)

features = list(result.stdout.splitlines())

for r in range(1, len(features) + 1):
    for combo in itertools.combinations(features, r):
        print('Testing with features [{}]'.format(', '.join(combo)))
        result = subprocess.run(['cargo', 'test', '--no-default-features', '--features', ','.join(combo)], cwd=_DIRECTORY, stdout=subprocess.PIPE,  stderr=subprocess.STDOUT, text=True)
        if result.returncode != 0:
            print(result.stdout)
            sys.exit(result.returncode)

sys.exit(0)
