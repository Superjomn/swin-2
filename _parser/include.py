from cimport._search import Include

files = [
    'InitThes.pyx',
    'Thesaurus.pyx',
]

for f in files:

    Include(f)
