from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

'''
setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("hitlist", ["__hitlist.pyx"])] 
)

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("hitlists", ["__hitlists.pyx"])] 
)

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("wordwidthlist", ["__wordwidthlist.pyx"])] 
)

'''
setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("hitindexer", ["__hitindexer.pyx"])] 
)

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("doclist", ["__doclist.pyx"])] 
)
'''

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("idxlist", ["__idxlist.pyx"])] 
)

'''
setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("_indexer", ["__indexer.pyx"])] 
)



