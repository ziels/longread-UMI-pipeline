#!/bin/bash
# DESCRIPTION
#    Script for trimming sequences based on gene primers.
#    This script is a part of the longread-UMI-pipeline.
#    
# IMPLEMENTATION
#    author	Søren Karst (sorenkarst@gmail.com)
#               Ryans Ziels (ziels@mail.ubc.ca)
#    license	GNU General Public License

### Terminal input ------------------------------------------------------------
IN_DIR=$1
IN_REGEX=$2
OUT_DIR=$3
TYPE=$4
THREADS=$5

#Format input
IN_DIR_F=$(echo $IN_DIR | sed -e 's/[,;\t]/ /g')
IN_REGEX_F=$(echo "$IN_REGEX" |\
  sed -e 's/^/-name "/g' \
      -e 's/$/"/g' \
      -e 's/[,;\t]/" -o -name "/g')

# Custom functions
cutadapt_wrapper(){
  # Input
  IN=$1
  OUT_DIR=$2
  TYPE=$3

  # Format input name
  local IN_NAME=${IN##*/}
  local IN_NAME=${IN_NAME%.*}

  # Load amplicon specific vars
  if [[ "$TYPE" == "rrna_8f2490r" ]]; then
    ADP1=AGRGTTYGATYMTGGCTCAG
    ADP2=GTTTGGCACCTCGATGTCG
    MIN_LENGTH=3000
    MAX_LENGTH=6000
  fi

  # Run cutadapt
  $CUTADAPT --untrimmed-output $OUT_DIR/$IN_NAME.tmp\
    -m $MIN_LENGTH -M $MAX_LENGTH -g $ADP1...$ADP2 \
    $IN > $OUT_DIR/${IN_NAME}.fa 2> $OUT_DIR/${IN_NAME}_log.txt
  $SEQTK seq -r $OUT_DIR/$IN_NAME.tmp |\
    $CUTADAPT \
    -m $MIN_LENGTH -M $MAX_LENGTH \
    -g $ADP1...$ADP2 - >> $OUT_DIR/${IN_NAME}.fa

    # For troubleshooting
    #2>> $OUT_DIR/${IN_NAME}_log.txt
    #--untrimmed-output $OUT_DIR/$IN_NAME.discarded 

  rm $OUT_DIR/$IN_NAME.tmp
}

export -f cutadapt_wrapper

# Trim sequences
mkdir $OUT_DIR
FIND_CMD="find $IN_DIR_F -maxdepth 2 -type f \( $IN_REGEX_F \)"
eval $FIND_CMD | $GNUPARALLEL --env cutadapt_wrapper -j 10 cutadapt_wrapper {} $OUT_DIR $TYPE  

# Testing
# Reverse complement adaptors
#ADP1RC=$(echo $ADP1 | rev | tr TACGRYSWMKVHDBN ATGCYRSWKMBDHVN)
#ADP2RC=$(echo $ADP2 | rev | tr TACGRYSWMKVHDBN ATGCYRSWKMBDHVN)

