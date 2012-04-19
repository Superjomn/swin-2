import os

path = 'query'
path2 = '../query'

print '_dir_', os.path.dirname(__file__)

print os.path.join(os.path.dirname(__file__), path2)

print os.path.abspath(__file__)
