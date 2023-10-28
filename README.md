# get-automatic-trajectory-for-GROMACS
This repository contains a script which is supposed to perform in an automated way the process to get a simulation with GROMACS.
These preprocessing and simulation steps are based on Tubiana's lesson for the course "Computational Biophysics" held at UniTN (a.y. 2023/2024).
Further explanations of the steps performed are explained at this [link](https://cbp-unitn.gitlab.io/QCB/tutorial2_gromacs). 

This simulation uses a single protein (without ligands or extra molecules) soluted into water. The simulation is performed in a cubic periodic space, the diameter of the system is set to 1.0.

## Usage

This bash script requires an argument, which is the path to the folder in which we are supposed to find:
- a .pdb file
- minim.mdp
- md.mdp
- npt.mdp
- nvt.mdp

### Example

In this repo you also find a simple example of an alanine dipeptide file that could be used to better comprehend the functioning of the script and files reqired. Once the files are extracted from the folder, the example simulation can be run with the following command:

`bash commands.sh <path_to_the_folder>`