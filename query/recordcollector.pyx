from query.models import Record
cdef class RecordCollector:
    def __cinit__(self):
        pass
    
    cdef object getRecord(self, object docIDs):
        '''
        返回形式
            [
                {
                    url:xxx,
                    title:xxx
                }
            ]
        '''
        cdef:
            unsigned int docID
            object record
            object res
        
        res = []
        for docID in docIDs:
            record = Record.filter(id = docID)[0]
            res.append(
                [
                    record.dectitle,
                    record.url,
                    record.date,
                    record.dectext,
                ]
            )

        return res
        
