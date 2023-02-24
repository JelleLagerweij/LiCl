#!/bin/bash
runfile=$(expr runMD_H)	# Server where to run
Nruneq=$(expr 1000)	# initiation timestep
Nrun1=$(expr 250)	# dt*Nrun = 0.25 ns of data per run
Nrun2=$(expr 1000)	# dt*Nrun = 1ns of data per run
Nrun3=$(expr 2500)	# dt*Nrun = 2.5ns of data per run
Nrun4=$(expr 5000)	# dt*Nrun = 2.5ns of data per run
Temp=$(expr 298.15)		# Temperature in K
Press=$(expr 1)			# Pressure in atm

N_wat=$(expr 500)		# Number of water molecules
N_salt=$(expr 9)		# Number of LiCl's per 1m solution
m=$(expr 6)				# Concentration file to use


for folder in running
do
	mkdir $folder
	cd $folder

	for dt in 1 #2
	do
		mkdir dt_$dt
		cd dt_$dt

		for i in 1 #2 3 4
		do
			mkdir $i
			cd $i

			# Coppying all needed files to run folder (alphabetical order)
			cp ../../../input/$runfile runMD
			cp ../../../input/simulation.in .
			cp ../../../input/copy_files.sh .
			cp ../../../input/forcefield.data .


			# Set simulation_preprocessing.in file values
			randomNumber=$(shuf -i 1-100 -n1)
			sed -i 's/R_VALUE/'$randomNumber'/' simulation.in
			sed -i 's/T_VALUE/'$Temp'/' simulation.in
			sed -i 's/P_VALUE/'$Press'/' simulation.in
			sed -i 's/dt_VALUE/'$dt'/' simulation.in
			sed -i 's/Nrun_eq_VALUE/'$Nruneq'/' simulation.in
			sed -i 's/Nrun1_VALUE/'$Nrun1'/' simulation.in
			sed -i 's/Nrun2_VALUE/'$Nrun2'/' simulation.in
			sed -i 's/Nrun3_VALUE/'$Nrun3'/' simulation.in
			sed -i 's/Nrun4_VALUE/'$Nrun4'/' simulation.in

			# Set filder location
			sed -i 's/run_FOLDER/'$i'/' copy_files.sh

			# Set runMD variables
			sed -i 's/JOB_NAME/KCl T is '${Temp%.*}' m is '$m' run '$i'/' runMD
			sed -i 's/INPUT/simulation.in/' runMD

			# Creating config folder
			mkdir config
			cd config
			cp ../../../../input/Li.xyz .
			cp ../../../../input/params.ff .
			cp ../../../../input/Cl.xyz .
			cp ../../../../input/water.xyz .

			# compute total number of Li and Cl
			N_salt=$(($m*$N_salt))

			# Create initial configuration using fftool and packmol
			~/software/lammps/la*22/fftool/fftool $N_wat water.xyz $N_salt Li.xyz $N_salt Cl.xyz -r 55 > /dev/null
			~/software/lammps/la*22/packmol*/packmol < pack.inp > packmol.out
			~/software/lammps/la*22/fftool/fftool $N_wat water.xyz $N_salt Li.xyz $N_salt Cl.xyz -r 55 -l > /dev/null

			# removing the force data from packmol as I use my own forcefield.data. copy data.lmp remove rest
			sed -i '12,27d' ./data.lmp
			cp data.lmp ../data.lmp
			cd ..
			rm -r config

			# Commiting run and reporting that
			sbatch runMD
			echo "Runtask commited: T="$Temp", m="$m", run " $i"."
			cd ..
		done
		cd ..
	done
	cd ..
done
cd ..
