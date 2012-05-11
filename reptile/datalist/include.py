import sys
sys.path.append('../../')

from cimport import Cimport

files = [
    'urlist.pyx',
    'List.pyx',
]

for f in files:
    Cimport(f)
