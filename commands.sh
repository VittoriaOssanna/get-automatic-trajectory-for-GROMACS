#!/bin/bash

# Check if the user provided an input directory as an argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <directory>"
  echo "This command requires one argument, which is the directory containing the .pdb file and the .mdp files."
  exit 1
fi

# Store the input directory path provided as an argument
input_directory="$1"

# Search for .pdb or .PDB files in the directory
pdb_file=$(find "$input_directory" -type f \( -iname "*.pdb" -o -iname "*.PDB" \) -print -quit)
#search for minim.mdp
minim_file=$(find "$input_directory" -type f -name "minim.mdp" -print -quit)
# Search for md.mdp
md_file=$(find "$input_directory" -type f -name "md.mdp" -print -quit)
# Search for npt.mdp
npt_file=$(find "$input_directory" -type f -name "npt.mdp" -print -quit)
# Search for nvt.mdp
nvt_file=$(find "$input_directory" -type f -name "nvt.mdp" -print -quit)


# Check if the files in pdb_file, minim_file, md_file, npt_file and nvt_file exist

if [ ! -f "$pdb_file" ]; then
  echo "The .pdb file does not exist. Exiting."
  exit 2
fi

if [ ! -f "$minim_file" ]; then
  echo "The minim.mdp file does not exist. Exiting."
  exit 2
fi

if [ ! -f "$md_file" ]; then
  echo "The md.mdp file does not exist. Exiting."
  exit 2
fi

if [ ! -f "$npt_file" ]; then
  echo "The npt.mdp file does not exist. Exiting."
  exit 2
fi

if [ ! -f "$nvt_file" ]; then
  echo "The nvt.mdp file does not exist. Exiting."
  exit 2
fi

#--------------------------STEP0

# Define the subfolder name
subfolder0="0_topology"

# Check if the subfolder exists, and create it if it doesn't
if [ ! -d "$input_directory/$subfolder0" ]; then
  mkdir "$input_directory/$subfolder0"
  echo "Created subfolder $subfolder0"
else
  echo "The subfolder $subfolder0 already exists. Exiting."
  exit 3
fi

# Run the pdb2gmx command using the stored pdb_file
cd "$input_directory/$subfolder0"
gmx pdb2gmx -f "../$pdb_relative_path" -o "dip_processed.gro"


echo "---------------------------------------------"
echo "end of step 0"
echo "---------------------------------------------"



#----------------------STEP1

# Define the subfolder name
subfolder1="1_simulationbox_solvation"

cd "../../"

# Check if the subfolder exists, and create it if it doesn't
if [ ! -d "$input_directory/$subfolder1" ]; then
  mkdir "$input_directory/$subfolder1"
  echo "Created subfolder $subfolder1"
else
  echo "The subfolder $subfolder1 already exists. Exiting."
  exit 3
fi

cd "$input_directory/$subfolder1"

gmx editconf -f "../$subfolder0/dip_processed.gro" -o "newbox.gro" -c -d 1.0 -bt cubic
gmx solvate -cp "newbox.gro" -cs spc216.gro -o "dip_solv.gro" -p "../$subfolder0/topol.top"


echo "----------------------------------------------"
echo "end of step 1"
echo "----------------------------------------------"

#---------------------STEP2


#Define the subfolder name
subfolder2="2_ions"

cd "../../"

# Check if the subfolder exists, and create it if it doesn't
if [ ! -d "$input_directory/$subfolder2" ]; then
  mkdir "$input_directory/$subfolder2"
  echo "Created subfolder $subfolder2"
else
  echo "The subfolder $subfolder2 already exists. Exiting."
  exit 3
fi

cd "$input_directory/$subfolder2"

gmx grompp -f "../../$minim_file" -c "../$subfolder1/dip_solv.gro" -p "../$subfolder0/topol.top" -o "ions.tpr"

gmx genion -s "./ions.tpr" -o "dip_solv_ions.gro" -p "../$subfolder0/topol.top" -pname NA -nname CL -conc 0.1 -neutral


echo "-----------------------------------------------"
echo "end of step 2"
echo "-----------------------------------------------"



# ---------------------STEP3

cd "../../"

subfolder3="3_energyminimization"

if [ ! -d "$input_directory/$subfolder3" ]; then
  mkdir "$input_directory/$subfolder3"
  echo "Created subfoler $subfolder3"
else 
  echo "The subfolder $subfolder3 already exixts. Exiting."
fi 

cd "$input_directory/$subfolder3"

gmx grompp -f "../../$minim_file" -c "../$subfolder2/dip_solv_ions.gro" -p "../$subfolder0/topol.top" -o "em.tpr"
gmx mdrun -v -deffnm em
gmx energy -f em.edr -o potential.xvg

echo "----------------------------------------------------"
echo "end of step 3"
echo "----------------------------------------------------"

#----------------------STEP4


cd "../../"

subfolder4="4_equilibration"

if [ ! -d "$input_directory/$subfolder4" ]; then
  mkdir "$input_directory/$subfolder4"
  echo "Created subfolder $subfolder4"
else
  echo "The subfolder $subfolder4 already exists. Exiting."
fi


cd "$input_directory/$subfolder4"

gmx grompp -f "../../$nvt_file" -c "../$subfolder3/em.gro" -r "../$subfolder3/em.gro" -p "../$subfolder0/topol.top" -o "nvt.tpr"
gmx mdrun -deffnm nvt

gmx energy -f "./nvt.edr" -o "temperature.xvg"

echo "=============================================================== $npt_file"

gmx grompp -f "../../$npt_file" -c "./nvt.gro" -r "./nvt.gro" -t "./nvt.cpt" -p "../$subfolder0/topol.top" -o "npt.tpr"
gmx mdrun -deffnm npt

gmx energy -f "./npt.edr" -o "pressure.xvg"


echo "------------------------------------------------------"
echo "end of step 4"
echo "------------------------------------------------------"

#-----------------------STEP5


cd "../../"

subfolder5="5_moleculardynamics"

if [ ! -d "$input_directory/$subfolder5" ]; then
  mkdir "$input_directory/$subfolder5"
  echo "Created subfolder $subfolder5"
else
  echo "The subfolder $subfolder5 already exists. Exiting."
fi

cd "$input_directory/$subfolder5"

gmx grompp -f "../../$md_file" -c "../$subfolder4/npt.gro" -t "../$subfolder4/npt.cpt" -p "../$subfolder0/topol.top" -o "./md_plain.tpr"

gmx mdrun -deffnm md_plain

echo "----------------------------------------------------"
echo "end of step 5"
echo "----------------------------------------------------"


#---------------------STEP6

cd "../../"

subfolder6="6_postprocessing"

if [ ! -d "$input_directory/$subfolder6" ]; then
  mkdir "$input_directory/$subfolder6"
  echo "Created subfolder $subfolder6"
else
  echo "The subfolder $subfolder6 alreasy exists. Exiting."
fi 

cd "$input_directory/$subfolder6"

gmx trjconv -s "../$subfolder5/md_plain.tpr" -f "../$subfolder5/md_plain.xtc" -o "./md_plain_noPBC.xtc" -pbc mol -center

echo ""
echo ""
echo "====================================="
echo "THE SIMULATION SHOULD BE COMPLETED :)"
echo "====================================="
echo ""
echo ""
