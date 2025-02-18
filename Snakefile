# TOP LEVEL RULES: @CTB

SKETCH_PARAMS = ["skipm2n3,k=24,scaled=50", "dna,k=21,k=31,scaled=50"]

# map various names to NCBI taxonomic ID
NAMES_TO_TAX_ID = {
    'ncbi-viruses': 10239,
    }

DATABASE_NAMES = [
    'ncbi-viruses'
]

rule make_collections:
    input:
        expand("collections/{NAME}.links.csv", NAME=set(NAMES_TO_TAX_ID)),
        'databases/ncbi-viruses.lineages.csv',
        "databases/ncbi-viruses.skip_m2n3.k=24.scaled=50.sig.zip",
        "databases/ncbi-viruses.dna.k=21.scaled=50.sig.zip",
        "databases/ncbi-viruses.dna.k=31.scaled=50.sig.zip",

rule build_database_skip:
    input:
        "collections/ncbi-viruses.mf.csv"
    output:
        "databases/ncbi-viruses.skip_m2n3.k=24.scaled=50.sig.zip"
    shell: """
        sourmash sig cat -k 24 --skipmer-m2n3 {input} -o {output}
    """

rule build_database_k21:
    input:
        "collections/ncbi-viruses.mf.csv"
    output:
        "databases/ncbi-viruses.dna.k=21.scaled=50.sig.zip"
    shell: """
        sourmash sig cat -k 21 --dna {input} -o {output}
    """

rule build_database_k31:
    input:
        "collections/ncbi-viruses.mf.csv"
    output:
        "databases/ncbi-viruses.dna.k=31.scaled=50.sig.zip"
    shell: """
        sourmash sig cat -k 31 --dna {input} -o {output}
    """

# just print out the gbsketch rule, rather than running it - it's easier
# to run it outside of snakemake
rule print_gbsketch:
    input:
        "collections/ncbi-viruses.links.csv",
    params:
        sigs="sketches/ncbi-viruses.zip",
        check_fail="gbsketch-check-fail.ncbi-viruses.txt",
        fail="gbsketch-fail.ncbi-viruses.txt",
        sketch_p=" ".join([f"-p {ps}" for ps in SKETCH_PARAMS])
    shell: """
        echo /usr/bin/time -v sourmash scripts gbsketch {input} \
            -n 9 -r 10 {params.sketch_p} \
            --failed {params.fail} --checksum-fail {params.check_fail} \
            -o {params.sigs} -c {threads} --batch 1000
    """


rule make_combined_manifest:
    output:
        "collections/ncbi-viruses.mf.csv"
    shell: """
       rm -f {output}
       sourmash sig collect -F csv sketches/*.zip -o {output} --abspath
       sourmash sig summarize {output}
    """

rule check_combined_manifest:
    input:
        mf="collections/ncbi-viruses.mf.csv",
        links="collections/ncbi-viruses.links.csv",
    output:
        missing="collections/ncbi-viruses-missing.links.csv",
    shell: """
        scripts/compare-sigs-and-links.py --sigs {input.mf} --links {input.links} \
            --save-missing {output.missing}
    """

rule get_tax:
    output:
        "collections/{NAME}.dataset-reports.pickle"
    params:
        tax_id = lambda w: NAMES_TO_TAX_ID[w.NAME]
    shell: """
       scripts/1-get-by-tax.py --taxons {params.tax_id} -o {output} \
          --all-genomes
    """

rule parse_links:
    input:
        datasets="collections/{NAME}.dataset-reports.pickle",
    output: 
        "collections/{NAME}.links.csv",
    shell: """
        scripts/2-output-directsketch-csv.py {input} -o {output}
    """

rule lineages_csv:
    input:
        "collections/{NAME}.links.csv",
    output:
        "databases/{NAME}.lineages.csv",
    shell: """
        scripts/taxid-to-lineages.taxonkit.py {input} -o {output}
    """
