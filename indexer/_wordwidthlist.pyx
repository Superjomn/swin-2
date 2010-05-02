Cimport  Type.pyx           swin2/indexer/Type.pyx
Cimport  wordwidthlist.pyx swin2/indexer/wordwidthlist.pyx


cdef HitList hitlist

cdef Hit hits[30]

hit_list = [
    [0, 2, 3],
    [0, 3, 3],
    [0, 3, 3],
    [0, 4, 3],
    [0, 4, 3],
    [0, 4, 3],
    #--7

    [1, 0, 4],
    [1, 3, 4],
    [1, 3, 4],
    [1, 3, 4],
    [1, 3, 4],
    #--5

    [3, 1, 4],
    [3, 2, 4],
    [3, 3, 4],
    [3, 3, 4],
    [3, 4, 4],
    [3, 4, 4],
    [3, 4, 4],
    [4, 1, 4],
    #--7
]
#init hitlist
for i, hit in enumerate(hit_list):
    hits[i].wordID = hit[0]
    hits[i].docID = hit[1]
    hits[i].format = hit[2]

hitlist._list = hits
hitlist.size = len(hit_list)
hitlist.space = len(hit_list)

cdef WordWidthList widlist
widlist = WordWidthList()

widlist.transWidth(hitlist , 0)
widlist.saveToText()


