import sys
sys.path.append('../')
from cimport import Cimport

files = [
    'indexer.pyx',
]

for f in files:
    Cimport(f)
