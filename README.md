# Handover

## Published in 


M. F. Özkoç, A. Koutsaftis, R. Kumar, P. Liu and S. S. Panwar, "The Impact of Multi-Connectivity and Handover Constraints on Millimeter Wave and Terahertz Cellular Networks," *in IEEE Journal on Selected Areas in Communications*, vol. 39, no. 6, pp. 1833-1853, June 2021, doi: 10.1109/JSAC.2021.3071852.


## Numerical Chain Computations
Located In .Theory/
Computes the chain numerically for various M values where M is the number of BS in the coverage area.


## Simulation
We simulate the scenario we analysed in our chain. We relax couple of assumptions to show that the chain analysis is capable of producing realistic results even with those assumptions. Namely, we relax the exponential discovery and handover execution time assumptions. In our simulations these values are fixed. Moreover we use various Base station (BS/AP) deployment scenarios where the value of alpha changes accordingly. Eventhough we use the expected value for alpha as a computation parameter for our chain analysis, in the simulations we have no such assumption.

**Reproducing the Simulation :**
The simulations require high number of realization of monte carlo simulations to completely characterize system. This is one of the key contributions of using the theoretical chain for system analysis. Nevertheless, we still use simulations to validate and motivate our chain. Since we require high number of realizations, it is useful to use a high performance computing cluster such as NYU-HPC. 
First clone the repository
```
git clone https://github.com/mustafafu/handover
cd handover/Simulations
```

Then edit the *submit.sbatch* file, change the email address. 
Edit the *SimulationLOS_thz.m* file accordingly for coverage radius, BS/AP deployment density, discovery and handover execution time, blocker density, and connectivity.
Then run,
```
sbatch --array=1-999 submit.sbatch
```
which will produce 999 iteration of simulations.

**Parsing the Simulation Data :**
After a large number of monte carlo simulations, we get an output file for each instance of the simulation. We are interested in the averaga outage probability and durations. A parsing of the data is required. 

For each coverage range, change the *DataProcess.m* script accordingly and it will produce a combined output in *./data/* folder. Submit the job as follows
```
sbatch submit_data_process.sbatch
```
  *Sharing data* : 
  ```
  setfacl -m u:mfo254:rwx -R $SCRATCH/[project]
  ```
  ```
  rsync -v /scratch/ps3857/handover/Simulation/data/Coverage23m/output*  /scratch/mfo254/handover/Simulation/data/Coverage23m/.
  ```
