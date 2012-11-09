#!/bin/bash
# Copyright (C) 2011 Ion Torrent Systems, Inc. All Rights Reserved

#--------- Begin command arg parsing ---------

CMD=`echo $0 | sed -e 's/^.*\///'`
DESCR="Create tsv and image files of mapped read coverage to a reference."
USAGE="USAGE:
  $CMD [options] <reference.fasta> <BAM file>"
OPTIONS="OPTIONS:
  -h --help Report usage and help
  -l Log progress to STDERR
  -G <file> Genome file. Assumed to be <reference.fasta>.fai if not specified.
  -D <dirpath> Path to Directory where results are written. Default: ./
  -O <file> Output file name for text data (per analysis). Use '-' for STDOUT. Default: 'summary.txt'
  -R <file> Output file name for reads and base coverage data. Default: None created
  -B <file> Limit coverage to targets specified in this BED file
  -V <file> Filepath table list of called Variants
  -P <file> Padded targets BED file for padded target coverage analysis"

# should scan all args first for --X options
if [ "$1" = "--help" ]; then
    echo -e "$DESCR\n$USAGE\n$OPTIONS" >&2
    exit 0
fi

SHOWLOG=0
BEDFILE=""
GENOME=""
WORKDIR="."
OUTFILE="summary.txt"
PADBED=""
VARSFILE=""
READSTATS=""

while getopts "hlB:G:D:O:P:V:R:" opt
do
  case $opt in
    l) SHOWLOG=1;;
    B) BEDFILE=$OPTARG;;
    G) GENOME=$OPTARG;;
    D) WORKDIR=$OPTARG;;
    O) OUTFILE=$OPTARG;;
    P) PADBED=$OPTARG;;
    V) VARSFILE=$OPTARG;;
    R) READSTATS=$OPTARG;;
    h) echo -e "$DESCR\n$USAGE\n$OPTIONS" >&2
       exit 0;;
    \?) echo $USAGE >&2
        exit 1;;
  esac
done
shift `expr $OPTIND - 1`

if [ $# -ne 2 ]; then
  echo "$CMD: Invalid number of arguments." >&2
  echo -e "$USAGE\n$OPTIONS" >&2
  exit 1
fi

REFERENCE=$1
BAMFILE=$2

if [ -z "$GENOME" ]; then
  GENOME="$REFERENCE.fai"
fi
if [ "$OUTFILE" == "-" ]; then
  OUTFILE=""
fi

#--------- End command arg parsing ---------

RUNPTH=`readlink -n -f $0`
RUNDIR=`dirname $RUNPTH`
#echo -e "RUNDIR=$RUNDIR\n" >&2

# Check environment

BAMROOT=`echo $BAMFILE | sed -e 's/^.*\///'`
BAMNAME=`echo $BAMROOT | sed -e 's/\.[^.]*$//'`

if [ $SHOWLOG -eq 1 ]; then
  echo "$CMD BEGIN:" `date` >&2
  echo "REFERENCE: $REFERENCE" >&2
  echo "MAPPINGS:  $BAMROOT" >&2
  echo "GENOME:    $GENOME" >&2
  if [ -n "$BEDFILE" ]; then
    echo "TARGETS:   $BEDFILE" >&2
  fi
  echo "WORKDIR:   $WORKDIR" >&2
  if [ -n "$OUTFILE" ];then
    echo "TEXT OUT:  $OUTFILE" >&2
  else
    echo "TEXT OUT:  <STDOUT>" >&2
  fi
fi

if ! [ -d "$RUNDIR" ]; then
  echo "ERROR: Executables directory does not exist at $RUNDIR" >&2
  exit 1
elif ! [ -d "$WORKDIR" ]; then
  echo "ERROR: Output work directory does not exist at $WORKDIR" >&2
  exit 1
elif ! [ -f "$GENOME" ]; then
  echo "ERROR: Genome (.fai) file does not exist at $GENOME" >&2
  exit 1
elif ! [ -f "$REFERENCE" ]; then
  echo "ERROR: Reference sequence (fasta) file does not exist at $REFERENCE" >&2
  exit 1
elif ! [ -f "$BAMFILE" ]; then
  echo "ERROR: Mapped reads (bam) file does not exist at $BAMFILE" >&2
  exit 1
elif [ -n "$BEDFILE" -a ! -f "$BEDFILE" ]; then
  echo "ERROR: Reference targets (bed) file does not exist at $BEDFILE" >&2
  exit 1
elif [ -n "$SNPSFILE" -a ! -f "$SNPSFILE" ]; then
  echo "ERROR: SNPs file does not exist at $SNPSFILE" >&2
  exit 1;
elif [ -n "$INDELSFILE" -a ! -f "$INDELSFILE" ]; then
  echo "ERROR: INDELs file does not exist at $INDELSFILE" >&2
  exit 1;
elif [ -n "$PADBED" -a ! -f "$PADBED" ]; then
  echo "ERROR: Padded reference targets (bed) file does not exist at $PADBED" >&2
  exit 1;
fi

# Get absolute file paths to avoid link issues in HTML
WORKDIR=`readlink -n -f "$WORKDIR"`
REFERENCE=`readlink -n -f "$REFERENCE"`
BAMFILE=`readlink -n -f "$BAMFILE"`
GENOME=`readlink -n -f "$GENOME"`

ROOTNAME="$WORKDIR/$BAMNAME"
if [ -n "$OUTFILE" ];then
  rm -f "${WORKDIR}/${OUTFILE}"
  OUTCMD=">> \"${WORKDIR}/${OUTFILE}\""
fi

############

# Basic on-target stats
if [ -n "$READSTATS" ]; then
  MREADS=`samtools view -c -F 4 "$BAMFILE"`
  TREADS=$MREADS
  PTREADS="100.0%"
  echo "Number of mapped reads:    $MREADS" > "${WORKDIR}/$READSTATS"
  if [ -n "$BEDFILE" ]; then
    TREADS=`samtools view -c -F 4 -L "$BEDFILE" "$BAMFILE"`
    if [ "$TREADS" -gt 0 ]; then
      PTREADS=`echo "$TREADS $MREADS" | awk '{printf("%.2f%%"),100*$1/$2}'`
    else
      PTREADS="0%"
    fi
  fi
  echo "Number of reads in sample ID regions: $TREADS" >> "${WORKDIR}/$READSTATS"
  echo "Percent reads in sample ID regions:   $PTREADS" >> "${WORKDIR}/$READSTATS"
  MREADS=`samtools depth "$BAMFILE" | awk '{c+=$3} END {printf "%.0f",c+0}'`
  echo "Total base reads in sample ID regions:    $MREADS" >> "${WORKDIR}/$READSTATS"
  PTREADS="100.0%"
  if [ -n "$BEDFILE" ]; then
    TREADS=`samtools depth -b "$BEDFILE" "$BAMFILE" | awk '{c+=$3} END {printf "%.0f",c+0}'`
    if [ "$TREADS" -gt 0 ]; then
      PTREADS=`echo "$TREADS $MREADS" | awk '{printf("%.2f%%"),100*$1/$2}'`
    else
      PTREADS="0%"
    fi
  fi
  echo "Percent base reads in sample ID regions: $PTREADS" >> "${WORKDIR}/$READSTATS"
  if [ -n "$PLUGIN_CHROM_X_TARGETS" ]; then
    XREADS=`samtools view -c -F 4 -q 11 -L "$PLUGIN_CHROM_X_TARGETS" "$BAMFILE"`
    YREADS=0
    if [ -n "$PLUGIN_CHROM_Y_TARGETS" ]; then
      YREADS=`samtools view -c -F 4 -q 11 -L "$PLUGIN_CHROM_Y_TARGETS" "$BAMFILE"`
    fi
    echo "Male sample ID region reads:   $YREADS" >> "${WORKDIR}/$READSTATS"
    echo "Female sample ID region reads: $XREADS" >> "${WORKDIR}/$READSTATS"
  fi
fi
