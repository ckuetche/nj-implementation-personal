#parse the matrix using awk, pass values to bash
#flatten matrix into temporary file for bash
awk '{
BEGIN {FS="\t";OFS="\t"}
NR==1 { #parse the header
    for (i=2;i<=NF;i++) { #skip first empty column, NF is total row of columns 
        header[i]=$i #the column name is now in this header array
    }
}
#parse the rows next
{
    row=$1 #the row is the first field, and the remaining fields are the distances from this taxa to the others
    for (j=2;j<=NF;i++) {
       col=header[i] #the column name is the name from the header
       if (row < col) { #assumes symmetry and prevents printing AB and BA, row > col for the latter
           key=row"_"col #build the combined key to be used later 
           print key"="$i #print out the pair and distance value
       }
    }
}' matrix.tsv > distances.txt

#now the temporary file has been created, populate an array

declare -A taxa
while IFS='=' read -r key val; do #the internal field separator is = between keys and values
    taxa["$key"]="$val"
done < distances.txt

#calculate all Q distances and find the smallest one
#sum distances per taxon
declare -A sum
#initialize all sums to zero
for pair in "${!taxa[@]}"; do
    IFS='_' read -r j k <<< "$pair"
    sum["$j"]=0
    sum["$k"]=0
done

for pair in "${!taxa[@]}"; do
    IFS='_' read j k <<<"$pair" #split pairs into separate sequences
    val="${taxa[$pair]}" #the value to be added already corresponds to the distance of each permutation containing the sequence
    sum["$j"]=$(echo "${sum[$j]}" + $val | bc -l) #add up the sums after initializing the sum as 0, iterates with pairs and adds the sequence to the correct key
    sum["$k"]=$(echo "${sum[$k]}" + $val | bc -l) #bc l allows floating point arithmetic
done

#calculate the Q distances and return the smallest one
declare -A qval
n=${#sum[@]}
for pair in "${!taxa[@]}"; do
    IFS='=' read a b <<<"$pair"
    d="${taxa[$pair]}"
    qi=$(echo "($n -2) * $d - ${sum[$a]} - ${sum[$b]}" | bc -l)
    qval["$pair"]="$qi"
done
#find pair with minimum Qvalue
min_q=""
min_pair=""

for pair in "${!qval[@]}"; do
    q="${qval[$pair]}"
    if [[ -z "$min_q" || $(echo "$q < $min_q" | bc -l) ]]; then
        min_q="$q"
        min_pair="$pair"
    fi
done

#collapse merged node and recompute distances
declare -A updated_taxa

#collect the other taxa
declare -A others
IFS='_' read -r a b <<<"$min_pair"
for pair in "${!taxa[@]}"; do
    IFS='_' read j k <<<"$pair"
    for taxon in "$j" "$k"; do #go over the isolated pairs
        if [[ taxon != a && taxon != b ]]; then
            others["$taxon"]=1 #ensures no duplicates
        fi
    done
done

#iterate over the others taxa and retrieve distances
#get distances A,K and B,K
new_node="${a}${b}"

for taxon in "${!others[@]}"; do
    pair1=${a}_$taxon
    pair2=$taxon_${a} #incase the symmetrical pair does not exist
    pair3=${b}_$taxon 
    pair4=$taxon_${b} #incase the symmetrical pair does not exist
    pair_ak="${taxa["$pair1"]:-${taxa["$pair2"]}}" #falls to default value if pair1 doesn't exist - no need to stress about order
    pair_bk="${taxa["$pair3"]:-${taxa["$pair4"]}}"
    pair_ab="${taxa[$min_pair]}" #only use raw distances, not q distances
    d_new=$(echo "($pair_ak + $pair_bk" - "$pair_ab)"/2 | bc -l) #calculate d(AB,k) for the merged node

    if [[ "$new_node" < "$taxon" ]]; then #standardize the ordering of taxon names, check which string comes first alphabetically
        new_key="${new_node}+${taxon}"
    else
        new_key="${taxon}_${new_node}"
    fi
    
    updated_taxa["$new_key"]="$d_new"
done
#remove all pairs including A or B in any permutation
for pair in "${!taxa[@]}"; do
    if [[ "$pair" == ${a}_* || "$pair" == *_${a} || "$pair" == ${b}_* || "$pair" == *_${b} ]]; then
        unset "taxa[$pair]"
    fi
done
#insert the new distances
for pair in "${!updated_taxa[@]}"; do
    taxa[$pair]="${updated_taxa[$pair]}"
done

#create a temporary debug file for distances

debug_distances_file="debug_distances.txt"

for pair in "${!updated_taxa[@]}"; do
    echo "$pair=${taxa[$pair]}"
done > "$debug_distances_file"

#rebuild the matrix again and output to file