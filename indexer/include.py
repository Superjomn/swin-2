import sys
sys.path.append('../')
from cimport import Cimport

files = [
    'hitlist.pyx',
    'hitlists.pyx',
    'sorter.pyx',
    'wordwidthlist.pyx',
    'hitindexer.pyx',
    'indexer.pyx',
    'doclist.pyx',
    'idxlist.pyx',
    '_wordwidthlist.pyx',
]

for f in files:
    Cimport(f)
