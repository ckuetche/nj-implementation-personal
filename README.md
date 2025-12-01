## Neighbor-Joining Algorithm (Bash + AWK Implementation) - In progress
## Problem Overview
This project implements the Neighbor-Joining (NJ) algorithm for phylogenetic tree construction in two separate "workflows" in Bash and AWK. The goal is to build the complete NJ workflow from scratch, starting with raw sequence data, compute pairwise distances, generate the Q-matrix, and iteratively join clusters without relying on high-level scientific libraries.
## Motivation
I built this project as a learning exercise and challenge inspired by my BIOL439 (Practical Bioinformatics) coursework. Can I implement a classical algorithm used in computational biology using only shell scripting tools? Working in Bash/AWK requires me to deeply understand every step of the NJ algorithm, especially with matrix operations and iterative updates that are usually handled by libraries.
## Current functionality
As of the writing of this README, the script will generate the initial distance matrix using a Hamming-distance-based scoring system, idenitfy the first neighbor pair (u) from the distance matrix, compute the Q-matrix (selecting candidate pairs), and contains core logic for distance updates/iterative joining that is mostly implemented.
## Work in Progress and Future Directions
So far, the work in progress involves checking the logic once again, and design a robust master-controller script that automatically repeats the NJ cycle until only two clusters remain. Since Bash lacks multidimensional array structures, it's challenging coordinating dynamic matrix shrinking and recalculating distances. I'm currently experimenting with further including AWK in the final workflow, and working on an AWK-only version to observe any meaningful differences in implementation and for experimental purposes. Future directions include:
Complete the automated NJ iteration loop with a master-controller script
Add tree-building output (Newick-Format)
Create the fully parallel AWK implementation and cross-validate results between versions
Extend scoring options beyong Hamming distance
