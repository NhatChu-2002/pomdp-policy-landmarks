#!/bin/bash 

#RADAR_REPO="/media/data_mount/mycode/RADAR/FD/src"
#TODO: Move this to the current repo
LANDMARK_FD_REPO="/c/AI_planning/Landmark_dump/FD_LANDMARK_DUMP"
# LANDMARK_FD_REPO=$(locate fast-downward.py|grep "FD_LANDMARK_DUMP" | head -n 1)
dom_file=$1
prob_file=$2
land_file=$3

# Dangerous if land_file is empty
#rm $land_file 
# Assume fact landmarks and the atom is always on third column and is always positive
# First extract all lines that start with LM
# Then remove the beggining of the line upto Atom \d+
# Then remove everying thing after the first closing peranthesis
# Sample line:
# LM 2 Atom on(crate0, crate3) (var0(0)->8) Achievers (9, 9)

#python ${LANDMARK_FD_REPO}/fast-downward.py --build "release64"   $dom_file $prob_file  --search "astar(lmcount(lm_factory=lm_hm(m=1)))"|grep -E "^LM "|sed 's/.*Atom //'|sed 's/).*/)/'|sed 's/(/ /'|sed 's/,//g'|sed 's/)//' > ${land_file}

#cp $1 /tmp/domain.pddl
#cp $2 /tmp/problem.pddl

python ${LANDMARK_FD_REPO}/fast-downward.py --build "release64"   $dom_file $prob_file  --search "astar(lmcount(lm_factory=lm_rhw(disjunctive_landmarks=true)))"|grep -E "LM " > ${land_file}

# python ${LANDMARK_FD_REPO}/fast-downward.py --build "release64"  $dom_file $prob_file  --search "lazy_greedy([lmcount(lm_factory=lm_rhw(disjunctive_landmarks=true))])" > ${land_file}
