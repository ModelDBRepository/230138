This code was used in: Masquelier T (2017) STDP allows close-to-optimal spatiotemporal spike pattern detection by single coincidence detector neurons. Neuroscience.
https://doi.org/10.1016/j.neuroscience.2017.06.032
Jan 2017
timothee.masquelier@cnrs.fr

The code is in STDP/src
The main script in STDP/src/main.m
It has a long header with some info.

plots.m can be launched afterwards to analyze the results.

perf.m computes some performance indicators
mean_perf.m averages batch results (after running batch.py)

batch.py is a Python script that launches multiple threads of main.m with different random seeds (see its header for more information)

All the numerical parameters are in STDP/src/param.m

The data is read/written in STDP/data/

