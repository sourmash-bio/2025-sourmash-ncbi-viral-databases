# 2025-sourmash-eukaryotic-databases

Build infrastructure for creating sourmash databases from NCBI for all
eukaryotic reference genomes.

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
