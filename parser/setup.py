from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("InitThes", ["InitThes.pyx"])]
)
'''

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("Thes", ["Thesaurus.pyx"])]
)

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("HashIndex", ["HashIndex.pyx"])]
)
'''
