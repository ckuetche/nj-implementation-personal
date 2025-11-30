declare -A sequences
declare -A raw_scores
declare -A normalized_scores
#load an array with the sequences
while IFS= read -r line; do
    sequenceID=$(echo $line | awk '{print $1}') #grab the sequenceID
    sequence=$(echo $line | awk '{print $2}') #grab the sequence
    sequences["$sequenceID"]+="$sequence" #populate the array with your sequences
done < inputfile.txt

#calculate the raw hamming distance
for candidate in "${!sequences[@]}"; do
    for other_sequence in "${!sequences[@]}"; do
        len1=${#sequences["$candidate"]}
        len2=${#sequences["$other_sequence"]}
        min_length=$(( len1 < len2 ? len1 : len2 ))
        #no need to skip the candidate sequence as it will give you the self alignment scores
        raw_score=0 #must declare the raw score for this specific combination of sequences
        for ((k=0; k<min_length; k++)); do
            c_base="${sequences["$candidate"]:k:1}" #compare substrings base by base
            o_base="${sequences["$other_sequence"]:k:1}"
            if [[ "$c_base" == "$o_base" ]]; then
                ((raw_score++)) #plus one for matches
            elif [[ "$c_base" == "-" || "$o_base" == "-" ]]; then
                raw_score=$((raw_score-2)) #minus 2 for gaps - penalty
            else
                ((raw_score--)) #minus one for mismatches
            fi
        done
        raw_scores["$candidate,$other_sequence"]=$raw_score #use combined keys
    done
done

#pass to awk to normalize distances for the distance matrix
#read the array to get the appropriate sequences - easier to pass to awk 
for pair in "${!raw_scores[@]}"; do
    IFS=',' read seq1 seq2 <<< "$pair" #herestring feeds input into read
    raw_ab="${raw_scores["$pair"]}" #S(A,B)
    raw_aa="${raw_scores["$seq1,$seq1"]}" #S(A,A)
    raw_bb="${raw_scores["$seq2,$seq2"]}" #S(B,B)
    
    #skip any missing values
    if [[-z "$raw_aa" || -z "$raw_ab" || -z "$raw_bb" ]]; then
        continue
    fi
    #pass to awk 
    cosine=$(awk -v s_aa="$raw_aa" -v s_bb="$raw_bb" -v s_ab="$raw_ab" 'BEGIN {
        norm=1-(s_ab/sqrt((s_aa)*(s_bb)))
        printf "%.4f\n", norm 
        }') #calculate and print to 4 decimal places
    normalized_scores["$pair"]+="$cosine" #populate the array
done

#print the final matrix
#print the header
printf "\t"
for id in "${!sequences[@]}"; do
    printf "%s\t" "$id" #prints out the sequences separated by tabs
done
echo #prints a newline
for id1 in "${!sequences[@]}"; do #prints the rows
    printf "%s\t" "$id"
    for id2 in "${!sequences[@]}"; do #column index
        key="$id1,$id2" #build the key for the cell
        printf "%s\t", "${normalized_scores["$key"]}" #print value at [row, col]
    done #to print top down just flip the loops
    echo
done