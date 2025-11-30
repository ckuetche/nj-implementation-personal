declare -A sequences
declare -A raw_scores
#load an array with the sequences
while IFS= read -r; do
    sequenceID=$(echo $line | awk '{print $1}') #grab the sequenceID
    sequence=$(echo $line | awk '{print $2}') #grab the sequence
    sequences["sequenceID"]+="$sequence" #populate the array with your sequences
done < inputfile.txt

#calculate the raw hamming distance
for candidate in "${!sequences[@]}"; do
    for other_sequence in "${!sequences[@]}"; do
        max_length=${#sequences["$candidate"]}
        other_length=${#sequences["$other_sequence"]}
        min_length=$(max_length < other_length ? max_length : other_length)
        #no need to skip the candidate sequence as it will give you the self alignment scores
        max_length=$({#candidate} < {#other_sequence} ? {#candidate} : {#other_sequence})
        raw_score=0 #must declare the raw score for this specific combination of sequences
        for ((k=0; k<=min_length; k++)); do
            c_base="${#sequences["$candidate"]:k:1}"
            o_base="${#sequences["$candidate"]:k:1}"
            if [[ "$c_base" == "$o_base" ]]; then
                ((raw_score++)) #plus one for matches
            elif [[ "$c_base" == "-" || "$o_base" == "-" ]]; then
                raw_score=$((raw_score-2))
            else
                ((raw_score--))
            fi
        done
        raw_scores["$candidate,$other_sequence"]=$raw_score
    done
done

#pass to awk to normalize distances for the distance matrix


    