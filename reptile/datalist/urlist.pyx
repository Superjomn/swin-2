Cimport List.pyx swin/reptile/datalist/List.pyx

class Urlist:
    def __init__(self):
        self.list = []
    
    def init(self, siteNum):
        ''' clear list to empty '''
        self.list = []
        self.siteNum = siteNum
        for i in range(siteNum):
            self.list.append(List())


    def find(self, siteID, url):
        '''
        find url in list 
        '''
        return self.list[siteID].find(url)

    def show(self):
        print 'show list'
        for i in range(self.siteNum):
            print '-'*50
            print self.list[i].show()

    def getAll(self):
        res = []
        for site in self.list:
            res.append( site.getAll() )
        return res


    def getNums(self):
        nums = []
        for l in self.list:
            nums.append(l.getSize())
        return nums

    def resume(self, lists):
        '''
        resume urlist from database
        lists = [
            [path, path,],
        ]
        '''
        _size = len(lists)
        self.init(_size)
        for i,_list in enumerate(lists):
            for p in _list:
                self.list[i].find(p)

