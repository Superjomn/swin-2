# -*- coding: utf-8 -*-
class List(list):
    'the runtime list for all the url list'
    def find(self, url):  
        '''
        用法：
            li.find('./index.php')
        '''
        l = len(self)  
        first = 0  
        end = l - 1  
        mid = 0  
        
        if l == 0:  
            self.insert(0,url)  
            return False  
        
        while first < end:  
            mid = (first + end)/2  
            if hash(url) > hash(self[mid]):
                first = mid + 1  
            elif hash(url) < hash(self[mid]):
                end = mid - 1  
            else:  
                break  
            
        if first == end:  
            if hash(self[first]) > hash(url):  
                self.insert(first, url) 
                return False  
            
            elif hash(self[first]) < hash(url):  
                self.insert(first + 1, url)  
                return False  
            
            else:  
                return True  
                
        elif first > end:  
            self.insert(first, url) 
            return False  
        else:  
            return True  

    def show(self):
        print '-'*50
        print 'list-'*10
        for i in range(len(self)):
            url = self[i]
            print hash(url),'__',url

    def getAll(self):
        '''
        取得所有信息 便于中断操作
        '''
        return self

class Urlist:
    def __init__(self):
        self.list = []
    
    def init(self, siteNum):
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
        return self.list


