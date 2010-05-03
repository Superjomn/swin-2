import sys
sys.path.append('../')
from cimport import Cimport

files = [
    'indexer.pyx',
    'doclist.pyx',
    'hitindexer.pyx',
]

for f in files:
    Cimport(f)
