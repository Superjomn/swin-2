from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread
import sys
sys.path.append('../')
from Config import Config
config = Config()

Cimport Hit.pyx     swin2/indexer/Hit.pyx
#导入类型
Cimport Type.pyx    swin2/indexer/Type.pyx

Cimport ../_parser/InitThes.pyx     swin2/_parser/InitThes.pyx

Cimport Sorter.pyx  swin2/indexer/Sorter.pyx

DEF STEP = 20

cdef class Indexer:
    cdef:
        #词库
        InitThes thes
        HitCtrl hitctrl
        HitSort hitsort
        object htmldb
        object htmlnum
        object ict

    def __cinit__(self):
        #database
        self.htmldb = htmldb.HtmlDB()
        self.htmlnum = self.htmldb.getHtmlNum()
        self.ict = Ictclas( config.getpath('parser', 'ict_configure_path') )
        self.hitctrl = HitCtrl()
        self.hitsort = HitSort()


    def run(self):
        '''
        循环运行主程序
        '''
        for i in range(self.htmlnum):
            self.htmldb.setRecordHandle(i)
            #level 1
            format1 = self.htmldb.getTitle() + self.htmldb.getUrlDec() 
            #level 2 string
            format2 = self.htmldb.getB() + self.htmldb.getHOne()
            #level 3 string
            format3 = self.htmldb.getContent() + self.htmldb.getHTwo()

            #开始分词及作处理
            self.indexStr(format1, 1)
            self.indexStr(format2, 2)
            self.indexStr(format3, 3)

    def indexStr(self, word, _format):
        '''
        word:词汇
        _format: 1 2 3 4
        '''
        FORMAT = {
            1   :   LOW,
            2   :   MID,
            3   :   TOP
        }

        LEVEL = {
            1   :   ONE,
            2   :   TWO,
            3   :   THREE,
            4   :   FOUR
        }

        wordID = self.thes.find(word)
        pos = self.thes.pos(len(word))
        docID = self.htmldb.getDocID()
        level = self.__getLevel(self.htmldb.getUrl())
        self.hitctrl.setFormat(FORMAT[_format])
        self.hitctrl.setLevel( LEVEL[level] )
        self.hitctrl.setWordID(wordID)
        self.hitctrl.setDocID(docID)
        self._lists[pos].append(self.hitctrl.getIndex())

    def sort(self):
        '''
        排序主程序
        单独为每一个pos内的index排序
        先依照wordID排序
        然后在相同wordID内进行docID的排序
        同时记录wordID的范围表
        '''
        for i in range(STEP):
            self.hitsort.init(i, self._lists[i].getList(), self._lists[i].getSize())
            self.hitsort.run()


    #此方法无效!!!!!!!!!!!!!!!!!
    cdef save(self):
        '''
        将index通过文件进行存储
        '''
        print 'begin to save'
        path = config.getpath('indexer', 'hits_path')
        cdef object fn

        for i in range(STEP):
            fn = path + str(i) + '.hit'
            cdef char *fname =  fn
            cdef FILE *fp=<FILE *>fopen(fname,"wb")
            fwrite(self._lists[i].getList() , sizeof(Hit), self._lists[i].getSize(), fp)
            fclose(fp)
        #save num of hits of each list
        numstr = ''
        for i in range(STEP):
            numstr += str(self._lists[i].getSize())+' '
        path = config.getpath('indexer', 'hits_num_path')
        f = open(path, 'w')
        f.write(numstr)
        f.close()


