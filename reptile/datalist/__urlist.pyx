from libc.stdlib cimport malloc,free,realloc

DEF ADD_PER = 100
DEF INIT_SPACE = 200

cdef class List:
    cdef: 
        long space
        long size
        long addPer
        long *__list

    def __cinit__(self):
        '''
        init
        '''
        self.size = 0
        self.initSpace()

    def __delloc__(self):
        print 'del all C space'
        free(self.__list)

    cdef void initSpace(self):
        self.space = INIT_SPACE
        self.__list = <long *>malloc( sizeof(long) * (self.space) )
        
    cdef addSpace(self):
        self.space += ADD_PER
        self.__list = <long *>realloc( self.__list, sizeof(long) * (self.space) )

    cdef insert(self, long i, long v):
        if i < 0:
            return False

        self.size += 1
        if self.size == self.space:
            self.addSpace()
        #向后耨动
        cdef long a = self.size-1
        while a >= i :
            self.__list[a] = self.__list[a-1]
            a -= 1
        self.__list[i] = v

    def find(self, url):  
        '''
        用法：
            li.find('./index.php')
        '''
        cdef:
            long l, first, end, mid, hv
        hv = hash(url)
        l = self.size
        first = 0  
        end = l - 1  
        mid = 0  
        
        if l == 0:  
            self.insert(0,hv)  
            return False  
        
        while first < end:  
            mid = (first + end)/2  
            if hv > self.__list[mid]:
                first = mid + 1  
            elif hv < self.__list[mid]:
                end = mid - 1  
            else:  
                break  
            
        if first == end:  
            if self.__list[first] > hv:  
                self.insert(first, hv) 
                return False  
            
            elif self.__list[first] < hv:  
                self.insert(first + 1, hv)  
                return False  
            
            else:  
                return True  
                
        elif first > end:  
            self.insert(first, hv) 
            return False  
        else:  
            return True  

    def getSize(self):
        return self.size

    def show(self):
        print '-'*50
        print 'list-'*10
        for i in range(self.size):
            url = self.__list[i]
            print url

    def getAll(self):
        '''
        取得所有信息 便于中断操作
        '''
        cdef:
            long i

        res = []
        for i in range(self.size):
            res.append(self.__list[i])
        return res


#--------------------------------------------------
#   End of List.pyx
#--------------------------------------------------


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

#--------------------------------------------------
#   End of urlist.pyx
#--------------------------------------------------

