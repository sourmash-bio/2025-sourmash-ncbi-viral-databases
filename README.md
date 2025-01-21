# 2025-sourmash-eukaryotic-databases

Build infrastructure for creating sourmash databases from NCBI for all
eukaryotic reference genomes.

The strategy is:

* use the directsketch plugin to build high rez (scaled=1000,
  k=21/31/51) for all euks, and put them all in a directory outside of
  sourmash-db;
* (this repo) make the various collection accession/taxid lists
  directly from NCBI;
* (this repo) build the full set of euk collections, downsampled
  to scaled=10_000

## How to install taxdump for taxonkit

You'll need to install the NCBI taxonomy taxdump for taxonkit, which is
used by pytaxonkit.

In some stable directory,
```
wget -c ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
tar -zxvf taxdump.tar.gz
mkdir -p $HOME/.taxonkit
ln -s names.dmp nodes.dmp delnodes.dmp merged.dmp $HOME/.taxonkit
```
