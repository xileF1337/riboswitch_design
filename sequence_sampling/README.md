# Testing RNAblueprint

This is a small test script for the Perl interface of RNAblueprint, a small
library implementing multi-constrained RNA sequence sampling, written by
Stefan Hammer.

Note: In the end, RNAblueprint was not used for our design of transcriptional
riboswitches.

## Dependencies

Please install BioConda, cf. `README.md` in the root directory.

TODO THIS IS NOT WORKING YET because the RNAblueprint package does not install
the Perl bindings. So up to now, please install RNAblueprint manually:
<https://github.com/ViennaRNA/RNAblueprint>

```bash
conda env create -f conda_env.yml
```

## Usage

First, activate the conda environment created above:

```bash
conda activate test_blueprint
```

Run the example script:

```bash
./test_RNAblueprint.pl
```
