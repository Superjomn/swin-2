cdef struct Hit:
    unsigned int wordID
    unsigned int docID
    unsigned char score     #二进制位

#2 byte to save format
cdef enum Format:   #1th - 2th
    # a | 00111111
    LOW 0   #00 00 0000
    MID 64  #01 00 0000
    TOP 128 #10 00 0000

#2 byte to save format
cdef enum Level:    #3th - 4th
    ONE 0       #00 00 0000
    TWO 16      #00 01 0000
    THREE 32    #00 10 0000
    FOUR 48     #00 11 0000

#记录单个wordid对应的笨pos内的范围
cdef struct WordWidth:
    long left
    long right
 
