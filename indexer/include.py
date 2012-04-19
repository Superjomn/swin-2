import sys
sys.path.append('../')
from cimport import Cimport

files = [
    'Indexer.pyx',
]

for f in files:
    Cimport(f)
