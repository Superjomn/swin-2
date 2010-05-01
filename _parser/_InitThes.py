# -*- coding: utf-8 -*-
from InitThes import InitThes

t = InitThes()

f = open('../data/bug_words.txt')
c = f.read()
f.close()

for w in c.split():
    print w, hash(w),' wordID:', t.find(w), 'pos', t.pos(hash(w))


