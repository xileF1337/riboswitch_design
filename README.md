# Tools for Designing Transcriptional Riboswitches

This repository contains scripts and libraries to design transcriptional
riboswitches and optimize them for a specific sequence context.

## Citation

If you use this software for your research, please cite:

C Günzel, F Kühnl, K Arnold, S Findeiß, C Weinberg, PF Stadler, and
Mario Mörl, "Beyond Plug and Pray: Context Sensitivity and in silico
Design of Artificial Neomycin Riboswitches", submitted

## Copyright and license

Copyright 2015-2020 Sven Findeiß & Felix Kühnl

The code provided in this package is free software released under the
GNU General Public License v3. Please refer to file `LICENSE`.

## Installation and usage

The `README.md` files in each of the subdirectories contain per-task
instructions to install dependencies and perform the desired step.

Generally, we recommend the usage of the package manager Conda / Bioconda to
provide all required dependencies. To install Conda, run the following
commands:

```bash
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
sh Miniconda3-latest-Linux-x86_64.sh
```

You may need to restart your shell.  Next, set up the Bioconda channels:

```
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
```

Now, please follow the instructions in the `README.md` files in the
subdirectories for the task you want to perform.

Futher information can be found in the official Bioconda docs:
<https://bioconda.github.io/user/install.html>
