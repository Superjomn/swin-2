import sys
sys.path.append('../')
from cimport import Cimport

files = [
    'sorter.pyx',
    'query.pyx',
]

for f in files:
    Cimport(f)