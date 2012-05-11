import sys
sys.path.append('../')
from cimport import Cimport

files = [
    'HashIndex.pyx',
    'Thes.pyx',
    'InitThes.pyx',
    'List.pyx',
]

for f in files:

    Cimport(f)
