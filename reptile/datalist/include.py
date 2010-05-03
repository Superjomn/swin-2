import sys
sys.path.append('../../')

from cimport import Cimport

files = [
    'urlist.pyx',
]

for f in files:
    Cimport(f)
