# 2025-sourmash-ncbi-viral-databases

Build infrastructure for creating sourmash databases from NCBI for all
viral genomes.

The strategy is:

* use the NCBI datasets API to retrieve accessions and taxids for all
  the viral genomes in NCBI; create a lineage CSV for them.
* use the directsketch plugin to build skip-mer sketches for all of them: `-p
  skipm2n3,k=24,scaled=50`

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
