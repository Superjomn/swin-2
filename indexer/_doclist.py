from doclist import InitDocList

doclist = InitDocList()

for i in range(9):
    print i, 'doc', doclist.get(i)
