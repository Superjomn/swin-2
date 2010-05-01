cdef getNumFromFile(path):
    '''
    如果文件中只包含一个num 则直接返回
    如果文件中包含多个num 则返回列表
    '''
    f = open(path)
    c = f.read()
    f.close()
    return int(c)

cdef getNumsFromFile(path):
    f = open(path)
    c = f.read()
    f.close()
    _res = []
    _split = c.split()
    for word in _split:
        _res.append(int(word))
    return _res
