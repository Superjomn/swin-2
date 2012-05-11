# -*- coding: utf-8 -*-
from InitThes import InitThes

t = InitThes()

c="中国 农业 大学"

for w in c.split():
    print w, hash(w),' wordID:', t.find(w), 'pos', t.pos(hash(w))


