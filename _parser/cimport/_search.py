'''
to fill the cython cimport pxd files bug
'''
class Cimport:
    def __init__(self):
        #list to save line and path that has 'include'
        self.cur_line = []
        self.lines = None
        self.outfile = ""
        self.infilename = None


    def open_file(self, filename):
        self.infilename = filename
        f = open(filename, 'r')
        self.lines = f.readlines()
        f.close()

        for i,line in enumerate(self.lines):
            #split line to words
            words = line.split()
            if len(words) < 2:
                continue

            if words[0] == 'Cimport':
                '''
                try to include file
                and copy content of that file to this scope
                '''
                print line
                path = words[1]
                self.cur_line.append(i)

    def include_files(self):
        for i,line in enumerate(self.lines):
            idx = -1
            try:
                idx = self.cur_line.index(i)
            except:
                idx = -1

            if idx is -1:
                '''
                this line does not include the file
                '''
                self.outfile += line + "\n"
            else:
                '''
                find include key word in this line
                copy files to this line
                '''
                words = line.split()
                include_file_name = words[1]
                f = open(include_file_name, 'r')
                c = f.read()
                f.close()
                self.outfile += c

    def save_outfile(self):
        filename = '__' + self.infilename
        f = open(filename, 'w')
        f.write(self.outfile)
        f.close()

        print '-'*50
        print "Includes Successfully Done!"
        print '-'*50

    def run(self, filename):
        self.open_file(filename)
        self.include_files()
        self.save_outfile()

def Include(filename):
    cimport = Cimport() 
    cimport.run(filename)
