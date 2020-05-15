# Designing Transcriptional Riboswitches

The script `design_riboswitches` automatically designs transcriptional
riboswitch candidates from a given aptamer according to a specific generation
pattern, and then applies several filters to remove unsuited constructs from
the generated set of switches.


## Output

TODO explain

-   header for numeric values of generating filter output:

        >ID:<                  >region of complementarity<    >linker length<
        >energy of construct<  >energy of constraint fold<    >energy difference<
        >z-score<              >distance of last bp in constraint fold<


## Description of generation step

-   developed by Sven Findeiss
-   general candidate construction:
    -   append random spacer sequence to aptamer
    -   append a sequence which is the reversed complement of the 3’ end
        of the aptamer
    -   append a perfect 8-nt poly U stretch
    -   afterwards: filter out inappropriate candidates

## Filtering step

-   developed by Sven Findeiss, extended by Felix Kuehnl


## Dependencies

Please install Bioconda, cf. `README.md` in the root directory. Then, run:

```bash
conda env create -f ./conda_env.yml
```

## Usage

First, activate the conda environment created above:

```bash
conda activate design_rs
```

Use the `-h` switch to get help:

```bash
./design_riboswitches -h
```

This is an exemplary run for the N1M7 aptamer (cf. file `aptamer_N1M7.fa`):

```bash
aptamerSequence='GACUGCUUGUCCUUUAAUGGUCCAGUC'
./design_riboswitches -d -foldPara "--noLP" -random 100 \
    -spacerDB ./spacer_db.txt -aptamerSe "$aptamerSequence" \
    -minPos 9 -steps 1,5,10 -seed 892050198
```

