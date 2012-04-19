from cimport.cimport import Cimport

files = [
    'InitThes.pyx',
    'Thesaurus.pyx',
]

for f in files:

    Cimport(f)
