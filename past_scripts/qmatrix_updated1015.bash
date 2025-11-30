#parse the matrix using awk, pass values to bash
#flatten matrix into temporary file for bash
awk '{
BEGIN {FS="\t";OFS="\t"}
NR==1 { #parse the header
    for (i=2;i<=NF;i++) { #skip first empty column, NF is total row of columns 
        header[i]=$i the column name is now in this header array
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
n=${#taxa[@]}
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



    


