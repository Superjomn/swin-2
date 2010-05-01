import sys
sys.path.append('../')
from cimport import Cimport

files = [
    'Thes.pyx',
    'InitThes.pyx',
]

for f in files:

    Cimport(f)
