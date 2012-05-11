# -*- coding: utf-8 -*-
from sourceparser.fileparser import TextFileParser

filetext = TextFileParser()
filetext.save('报名表', 'http://www.cau.edu.cn/index.doc', 0)
