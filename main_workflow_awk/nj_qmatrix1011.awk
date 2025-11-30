#!/usr/bin/awk -f

BEGIN {
	FS="\t"
}

NR == 1 {
	for (i=2; i<=NF; i++) {
		taxa[i]=$i
	}
	next
	n=length(taxa)
}
#populate the distance matrix named dist
{
	row=$1
	for (i=2;i<=NF;i++) {
		col=taxa[i]
		if (row != col && $i != 0) {
			dist[row, col]=$i
			dist[col, row]=$i #ensures symmetry
		}
	}
}
#Compute total distances for each taxa
END {
	for (key in dist) {
		split(key, arr, SUBSEP) #split pairs
		i=arr[1]
		j=arr[2]
		totalDist[i]+=dist[i, j] #use the previous distance matrix to find distance for a taxa
	}
#Compute Q(i, j) and find the minimum
	minQ=999999
	for (key in dist) {
		split(key, arr, SUBSEP)
		i=arr[1]
		j=arr[2]
		if (i==j) continue
		Q=(n-2)*dist[i, j] - totalDist[i] - totalDist[j]
		print "Q(" i "," j ")= " Q #ouput the Q distance
		if (Q<minQ) {
			minQ=Q
			minPair=key
		}
	}

	#output the pair to join as u
	split(minpair, arr, SUBSEP)
	i=arr[1]
	j=arr[2]
	print "Join:", i, j, "with Q=", minQ
}


