# -*- coding: utf-8 -*-
import os
'''
to fill the cython cimport pxd files bug
'''
#记录已经导入的模块
import_paths = []

def _cimport(filename):
    '''
    open a file and parse key word: Cimport
    '''
    cur_line = []
    out_file = ""

    f = open(filename)
    lines = f.readlines()
    f.close()
    for i,line in enumerate(lines):
        words = line.split()
        if len(words) < 3:
            out_file += line
            continue
        if words[0] == 'Cimport':
            '''
            try to include file
            and copy content of that file to this scope
            '''
            print line
            path = words[1]
            key = words[2]
            #判断是否重复导入
            cur_line.append(i)
            if key in  import_paths:
                continue
            else:
                import_paths.append(key)
                out_file += _cimport(path)
        else:
            out_file += line

    end_line = "-"*50+"\n"
    end_line += "   End of %s"%filename+"\n"
    end_line += "-"*50+"\n\n"
    out_file += end_line
    return out_file

def Cimport(filename):
    out_file = _cimport(filename)
    out_file_name = '__' + filename
    f = open(out_file_name, 'w')
    f.write(out_file)
    f.close()
    print '-'*50
    print "     Includes Successfully Done!"
    print '-'*50
    
