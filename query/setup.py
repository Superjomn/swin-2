from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

'''
setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("sorter", ["__sorter.pyx"])] 
)

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("_query", ["__query.pyx"])] 
)

'''

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("Queryer", ["__Queryer.pyx"])] 
)

