// Deft is a density functional package developed by the research
// group of Professor David Roundy
//
// Copyright 2010 The Deft Authors
//
// Deft is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// You should have received a copy of the GNU General Public License
// along with deft; if not, write to the Free Software Foundation,
// Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
//
// Please see the file AUTHORS for a list of authors.

#include <stdio.h>
#include <time.h>
#include "Functionals.h"
#include "equation-of-state.h"


int main(int, char **) { 
  const double kB = 3.16681539628059e-6; // This is Boltzmann's constant in Hartree/Kelvin
  const double kT = kB*298; // Room temperature
  FILE *o = fopen("paper/figs/entropy.dat", "w");

  Functional f = OfEffectivePotential(SaftFluidSlow(water_prop.lengthscale,
                                                    water_prop.epsilonAB, water_prop.kappaAB,
                                                    water_prop.epsilon_dispersion,
                                                    water_prop.lambda_dispersion,
                                                    water_prop.length_scaling, 0));
  double n_1atm = pressure_to_density(f, water_prop.kT, atmospheric_pressure,
				      0.001, 0.01);
  
  double mu_satp = find_chemical_potential(f, water_prop.kT, n_1atm);
  
  f = OfEffectivePotential(SaftFluidSlow(water_prop.lengthscale,
                                         water_prop.epsilonAB, water_prop.kappaAB,
                                         water_prop.epsilon_dispersion,
                                         water_prop.lambda_dispersion, water_prop.length_scaling, 
					 mu_satp));

  Functional S = OfEffectivePotential(SaftEntropy(water_prop.lengthscale, 
						  water_prop.epsilonAB, water_prop.kappaAB,
                                                  water_prop.epsilon_dispersion, 
						  water_prop.lambda_dispersion,
                                                  water_prop.length_scaling));
  
  //double nl=0.004938863;        // liquid density in bohr^-3   
  //double nv=1.141e-7;         //vapor density in bohr^-3

  for (double dens=1e-8; dens<=0.006; dens *= 1.01) {
    double V = -kT*log(dens);
    //double Vl = -kT*log(nl);
    double ff = f(kT, V);
    double SS = S(kT, V);
    //printf("n = %g\tS/n = %g\n", dens, S(V)/dens);
    fprintf(o, "%g\t%g\t%g\t%g\t%g\n", dens, ff, SS, ff + kT*SS, kT*SS); //Prints n, F, S, U, TS to data file
    fflush(o);
  }
  fclose(o);
}
