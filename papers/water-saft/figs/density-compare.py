#!/usr/bin/env python

#need this to run without xserver
import matplotlib
matplotlib.use('Agg')

import math
import matplotlib.pyplot as pyplot
import numpy
import pylab

nm = 18.8972613
gpermL=4.9388942e-3/0.996782051315 # conversion from atomic units to mass density

colors = ["#44dd55", "#3377aa", "#002288"]
radii = [ 0.2, 0.6, 1.0 ]

for i in range(len(radii)):
    newdata = pylab.loadtxt('figs/single-rod-slice-%04.2f.dat' % (2*radii[i]))
    hugdata = pylab.loadtxt('figs/hughes-single-rod-slice-%04.2f.dat' % (2*radii[i]))
    rnew = newdata[:,0]/nm
    rhug = hugdata[:,0]/nm
    newdensity = newdata[:,1]/gpermL
    hugdensity = hugdata[:,1]/gpermL
    pylab.plot(rnew, newdensity, color = colors[i], linestyle='-')
    pylab.plot(rhug, hugdensity, color = colors[i], linestyle='--')

pyplot.hlines(1, 0, 1.3, 'k', '--')

#plot properties
pyplot.ylabel('                                      Density (g/mL)')
pyplot.xlabel('Radius (nm)')
pyplot.xlim(0, 1.3)
pyplot.savefig('figs/density-compare.eps')
