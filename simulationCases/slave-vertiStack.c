
/**
# "Slave" solver for the coupling example

This should be read in combination with [master.c](). */

#include "grid/multigrid.h"
#include "navier-stokes/centered.h"

#include "slave.h"

double Reynolds = 1.;
int maxlevel = 9;
face vector muv[];

double D = 0.5, U0 = 1.;

event properties (i++)
{
  foreach_face()
    muv.x[] = fm.x[]*D*U0/Reynolds;
}

u.n[left]  = dirichlet(U0);
p[left]    = neumann(0.);
pf[left]   = neumann(0.);

u.n[right] = neumann(0.);
p[right]   = dirichlet(0.);
pf[right]  = dirichlet(0.);

u.n[top] = neumann(0.);
u.t[top] = neumann(0.);
p[top]   = dirichlet(0.);
pf[top]  = dirichlet(0.);

u.n[bottom] = dirichlet(0.);
u.t[bottom] = dirichlet(0.);
p[bottom]   = neumann(0.);
pf[bottom]  = neumann(0.);

event init (t = 0)
{
  foreach()
    u.x[] = U0;
}

event logfile (i++)
  fprintf (stderr, "slave %d %g %g %d %d\n", i, t, dt, mgp.i, mgu.i);

event movies (t = 0; t += 0.05; t <= 30.)
{
  scalar vel[];
  foreach() {
    vel[] = sqrt(sq(u.x[]) + sq(u.y[]));
  }
  output_ppm (vel, file = "vel-slave-vertStack.mp4",
	      min = 0.0, max = 1.0, linear = true, n = 256);
  /*
  for uncouple, use
  output_ppm (vel, file = "vel-slave-vertStack-uncoupled.mp4",
	      min = 0.0, max = 1.0, linear = true, n = 256);
  */
}

int main()
{
  L0 = 8. [1];
  origin (-L0/2., -L0/2.);
  N = 128;
  mu = muv;
  run();
}
