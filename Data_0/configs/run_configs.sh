#!/bin/bash

module load 2023
module load SciPy-bundle/2023.07-gfbf-2023a

# Ensure the script exits on error
set -e

# Check the number of arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <N> <T in Celsius> <blocks>"
    exit 1
fi

# Set variables
N=$1
T_C=$2

n_licl=10
n_w=1100

# Call Python script and capture its output
output=$(python3 boxsizes.py $n_licl $n_w $T_C)
if [ $? -ne 0 ]; then
    echo "Python script failed"
    exit 1
fi

# Extract r and L values from Python script output
r=$(echo "$output" | awk 'NR==1')
L=$(echo "$output" | awk 'NR==2')
T=$(echo "$output" | awk 'NR==3') # temperature in K

# Create and navigate to the temporary directory
rm -rf temp_$T_C
mkdir temp_$T_C
cd temp_$T_C

# Corrected for loop condition
for ((i=1; i<=$N; i++))  # C style for loop
do
    rm -rf config
    mkdir config
    cd config
    cp ../../water.xyz .e
    cp ../../K.xyz .
    cp ../../OH.xyz .
    cp ../../params.ff .

    # Create initial configuration using fftool and packmol
    ~/software/lammps/lammps2018/fftool/fftool $n_w water.xyz $n_licl K.xyz $n_licl OH.xyz -r $r > /dev/null
    echo "seed -1" >> pack.inp
    ~/software/lammps/lammps2018/packmol*/packmol < pack.inp > packmol.out

    # Modify simbox.xyz for Lattice values
    # sed -i 's/Built with Packmol/Lattice="'$L' 0.0 0.0 0.0 '$L' 0.0 0.0 0.0 '$L'"/' simbox.xyz
    ~/software/lammps/lammps2018/fftool/fftool $n_w water.xyz $n_licl K.xyz $n_licl OH.xyz -r $r -l > /dev/null

    # Copy the POSCAR file and clean up
    sed -i '13,28d' data.lmp
    mv data.lmp ../data.lmp_$i
    cd ..
    rm -rf config
done

