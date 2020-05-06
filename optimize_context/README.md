# Sequence Context optimization for Transcrptional Riboswitches

For a given riboswitch and a 5' leader sequence, design a decoupling sequence
insert placed between both sequences that minimizes the structural
interference between leader and riboswitch, i.e., which minimizes the
probability that base pairs form between these two domains.

## Dependencies

Please install BioConda, cf. `README.md` in the root directory. Then, run:

```bash
conda env create -f ./conda_env.yml
conda activate opt_ctx
cpanm ./Math-Optimize-Walker-v0.1.0.tar.gz
```

## Usage

First, activate the conda environment created above:

```bash
conda activate opt_ctx
```

Use the `-h` switch to get help.

```bash
./design_inserts -h
```

For a full example call as the one used to create the decoupling leader
sequence from the paper, refer to file `run_insert_designer.sh`.
