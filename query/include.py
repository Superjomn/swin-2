import sys
sys.path.append('../')
from cimport import Cimport

files = [
    'sorter.pyx',
    'query.pyx',
    'Queryer.pyx',
]

for f in files:
    Cimport(f)
