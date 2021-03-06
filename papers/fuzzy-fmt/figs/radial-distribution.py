#!/usr/bin/python

from __future__ import division
# We need the following two lines in order for matplotlib to work
# without access to an X server.
import matplotlib
matplotlib.use('Agg')
from pylab import *
from scipy.special import erf
import os

if len(sys.argv) != 2:
    print("Usage:  " + sys.argv[0] + ' filling-fraction')
    exit(1)

ff = float(sys.argv[1])
#arg ff = [10, 20, 30, 40, 50, 60, 70, 80]

#Constants and variables
#k_b = 8.6173324*10**(-5) # in eV
dT = .001
#Temp_max = 600 #in Kelvin
#Temp = arange(.001, .1 + dT/2, dT)
V0 = 1
#betaV0 = V0/Temp
R = 1# in Angstroms
density = arange(0, .8 - .001/2, .001)/(4*pi/3)
#gamma = 2*((sqrt(pi*betaV0)+sqrt(pi*betaV0-16*sqrt(betaV0)))/8)**2
#sg = sqrt(gamma)

eta = density*4*pi/3
#P_cs = density*.001*(1+eta+eta**2-eta**3)/(1-eta)**3
P_cs = density*(1+eta+eta**2)/(1-eta)**3
#plot(eta,P_cs/.001, 'k',linewidth=2, label = 'Hard spheres')


colors = { 0.1: 'r', 0.01: 'm', 0.001: 'b', 0.0001: 'c', 0.00001: 'g' }

density = (ff/100)/(4*pi/3)
phs = density*(1+(ff/100)+(ff/100)**2)/(1-(ff/100))**3
for temp in [0.1, 0.01, 0.001, 0.0001]:
  # input: 'figs/mc-0.%02d00-*.dat.gradial' % (ff)
  fname = 'figs/mc-0.%02d00-%.4f.dat.gradial' % (ff, temp)
  if os.path.exists(fname):
    print 'found', fname
    g = loadtxt(fname)
    plot(g[:,0], g[:,1], colors[temp] + '-', label='T = %g' % temp)
    xlim(xmax=floor(max(g[:,0])))
  else:
    print 'could not find', fname

title('Radial distribution function at packing fraction %g' % (ff/100))
xlabel('radius')
ylabel('g')
legend(loc = 'best')
savefig('figs/radial-distribution-%02d.pdf' % (ff), bbox_inches=0)

show()
