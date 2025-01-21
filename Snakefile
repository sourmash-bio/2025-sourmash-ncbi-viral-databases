# TOP LEVEL RULES
# * make_collections (default rule) - makes all the link collections etc
# * databases - builds the downsampled databases
# * print_gbsketch - print out the directsketch command to make missing euks

EUK_SKETCHES = '/group/ctbrowngrp5/2025-genbank-eukaryotes/*.sig.zip'
DATABASE_SCALED = 10_000
DATABASE_KSIZES = [21, 31, 51]

# map various names to NCBI taxonomic ID
NAMES_TO_TAX_ID = {
    'eukaryotes': 2759,
    'metazoa': 33208,
    'plants': 33090,
    'fungi': 4751,
    'bilateria': 33213,
    'vertebrates': 7742,
    }

ADD_OTHER = [
    'collections/bilateria-minus-vertebrates.links.csv',
    'collections/metazoa-minus-bilateria.links.csv',
    'collections/eukaryotes-other.links.csv',
    ]

DATABASE_NAMES = [
    'fungi',
    'eukaryotes-other',
    'metazoa-minus-bilateria',
    'bilateria-minus-vertebrates',
    'plants',
    'vertebrates',
]

rule make_collections:
    input:
        expand("collections/{NAME}.links.csv", NAME=set(NAMES_TO_TAX_ID)),
        expand("collections/{NAME}.links.csv", NAME=DATABASE_NAMES),
        ADD_OTHER,
        'databases/eukaryotes.lineages.csv',
        'collections/upsetplot.png',
        "collections/eukaryotes-missing.links.csv"

rule databases:
    input:
        expand("databases/{db}.k51.sig.zip", db=DATABASE_NAMES),


# just print out the gbsketch rule, rather than running it - it's easier
# to run it outside of snakemake
rule print_gbsketch:
    input:
        "collections/eukaryotes-missing.links.csv",
    params:
        sigs="eukaryotes-missing.sig.zip",
        check_fail="eukaryotes-missing.gbsketch-check-fail.txt",
        fail="eukaryotes-missing.gbsketch-fail.txt",
    shell: """
        echo /usr/bin/time -v sourmash scripts gbsketch {input} \
            -n 9 -r 10 -p k=21,k=31,k=51,dna \
            --failed {params.fail} --checksum-fail {params.check_fail} \
            -o {params.sigs} -c {threads} --batch 50
    """


rule make_combined_manifest:
    output:
        "collections/eukaryotes.mf.csv"
    shell: """
       rm -f {output}
       sourmash sig collect -F csv {EUK_SKETCHES} -o {output} --abspath
       sourmash sig summarize {output}
    """

rule check_combined_manifest:
    input:
        mf="collections/eukaryotes.mf.csv",
        links="collections/eukaryotes.links.csv",
    output:
        missing="collections/eukaryotes-missing.links.csv",
    shell: """
        scripts/compare-sigs-and-links.py --sigs {input.mf} --links {input.links} \
            --save-missing {output.missing}
    """

rule downsample:
    input:
        expand("databases/{NAME}.k51.s100_000.sig.zip", NAME=DATABASE_NAMES),

rule merge:
    input:
        expand("databases/{NAME}-merged.k51.s100_000.sig.zip", NAME=DATABASE_NAMES),

rule upset_plot:
    input:
        expand("collections/{NAME}.links.csv", NAME=set(NAMES_TO_TAX_ID)),
        ADD_OTHER,
    output:
        'collections/upsetplot.png',
    shell: """
        scripts/make-upset.py {input} -o {output}
    """

rule get_tax:
    output:
        "collections/{NAME}.dataset-reports.pickle"
    params:
        tax_id = lambda w: { **NAMES_TO_TAX_ID }.get(w.NAME)
    shell: """
       scripts/1-get-by-tax.py --taxons {params.tax_id} -o {output}
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

### specific subsets/groups

rule make_invertebrates_csv:
    priority: 10
    input:
        sub_from='collections/bilateria.links.csv',
        sub='collections/vertebrates.links.csv',
    output:
        'collections/bilateria-minus-vertebrates.links.csv',
    shell: """
        ./scripts/subtract-links.py -1 {input.sub_from} \
            -2 {input.sub} -o {output}
    """

rule make_metazoa_sub_bilateria_csv:
    priority: 10
    input:
        sub_from='collections/metazoa.links.csv',
        sub='collections/bilateria.links.csv',
    output:
        'collections/metazoa-minus-bilateria.links.csv',
    shell: """
        ./scripts/subtract-links.py -1 {input.sub_from} \
            -2 {input.sub} -o {output}
    """

rule eukaryotes_other_csv:
    priority: 10
    input:
        sub_from='collections/eukaryotes.links.csv',
        sub=['collections/metazoa.links.csv',
             'collections/plants.links.csv',
             'collections/fungi.links.csv',
             ]
    output:
        'collections/eukaryotes-other.links.csv',
    shell: """
        ./scripts/subtract-links.py -1 {input.sub_from} \
            -2 {input.sub} -o {output}
    """

ruleorder: make_invertebrates_csv > make_metazoa_sub_bilateria_csv > eukaryotes_other_csv > parse_links    

# @CTB database preparation rules

rule downsample_sig:
    input:
        mf="collections/eukaryotes.mf.csv",
        pl="collections/{NAME}.links.csv",
    output:
        "databases/{NAME}.k{KSIZE}.sig.zip",
    shell: """
        sourmash sig downsample -k {wildcards.KSIZE} --scaled {DATABASE_SCALED} \
            --picklist {input.pl}:accession:ident \
            {input.mf} -o {output}
    """

rule merge_sig:
    input:
        "downsampled/{NAME}.k51.s100_100.sig.zip",
    output:
        "merged/{NAME}-merged.k51.s100_100.sig.zip",
    shell: """
        sourmash sig merge -k 51 -s 100_000 {input} -o {output} \
           --set-name {wildcards.NAME}-merged
    """

