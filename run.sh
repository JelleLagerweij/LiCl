#!/bin/bash

# General Simulation settings
T_START=15  # degree celcius
T_STOP=15  # degree celcius
T_STEP=10  # degree celcius
N_BLOCKS=1  # number of blocks

# Simulation box specific settings
n_w=1100
n_licl=20

# STARTUP CODE
for ((temp=$T_START; temp<=$T_STOP; temp+=$T_STEP));
do
    rm -rf temp_$temp
    mkdir temp_$temp
    cd temp_$temp

    T_K=$(echo "$temp + 273.15" | bc)
    for ((i=1; i<=$N_BLOCKS; i++));
    do
        mkdir "run_$i"
        cd "run_$i"

        # SETUP CONFIGUARTION
        # copy nescecary files
        mkdir config
        cd config
        cp ../../../Data_0/configs/water.xyz .
        cp ../../../Data_0/configs/Li.xyz .
        cp ../../../Data_0/configs/Cl.xyz .
        cp ../../../Data_0/configs/params.ff .

        # Ask python for the right box size
        output=$(python3 ../../../Data_0/configs/boxsizes.py $n_licl $n_w $temp)
        if [ $? -ne 0 ]; then
            echo "Python script failed"
            exit 1
        fi

        # Extract r and L values from Python script output
        r=$(echo "$output" | awk 'NR==1')  # molar density
        L=$(echo "$output" | awk 'NR==2')  # Box size
        T_K=$(echo "$output" | awk 'NR==3') # temperature in K

        # Create initial configuration using fftool and packmol
        ~/software/lammps/lammps2018/fftool/fftool $n_w water.xyz $n_licl Li.xyz $n_licl Cl.xyz -b $L > /dev/null
        echo "seed -1" >> pack.inp
        ~/software/lammps/packmol2025/packmol < pack.inp > packmol.out

        # Modify simbox.xyz for Lattice values
        # sed -i 's/Built with Packmol/Lattice="'$L' 0.0 0.0 0.0 '$L' 0.0 0.0 0.0 '$L'"/' simbox.xyz
        ~/software/lammps/lammps2018/fftool/fftool $n_w water.xyz $n_licl Li.xyz $n_licl Cl.xyz -b $L -l > /dev/null

        # Copy the POSCAR file and clean up
        sed -i '13,28d' data.lmp
        mv data.lmp ../data.lmp
        cd ..
        rm -rf config


        # Change the inputs for the simulation
        cp ../../Data_0/simulation.lammps .
        cp ../../Data_0/forcefield.data .
        cp ../../Data_0/runMD .

        sed -i 's/TEMPERATURE/'$T_K'/g' simulation.lammps
        sed -i 's/JOBNAME/MD_'$temp'_run_'$i'/g' runMD

        # RUN THE SIMULATION
        # mpirun -np 6 --bind-to socket --map-by socket \
        #     --x OMP_NUM_THREADS=1 \
        #     ~/software/lammps/lammps2025/build/lmp -in simulation.lammps -sf omp -pk omp 1
        # echo "Done with OPENMP LAMMPS RUN"
        # echo -e "\n\n\n\n\n"
    
        cd ..
        echo "done with submitting block $block run $i"
        echo "Temp = $T_K, r = $r mol/l, L = $L angstrom"
    done
    cd ..
done