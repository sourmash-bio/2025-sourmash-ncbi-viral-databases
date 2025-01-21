DATABASE_SCALED=10_000
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
    'plants'
]

rule default:
    input:
        expand("collections/{NAME}.links.csv", NAME=set(NAMES_TO_TAX_ID)),
        ADD_OTHER,
        'databases/eukaryotes.lineages.csv',
        'collections/upsetplot.png',


# @CTB replace sketches/*.sig.zip with:
# /group/ctbrowngrp5/2025-genbank-eukaryotes/*.sig.zip
rule make_combined_manifest:
    output:
        "collections/eukaryotes.mf.csv"
    shell: """
       rm -f {output}
       sourmash sig collect -F csv sketches/*.sig.zip \
          -o {output}
       sourmash sig summarize {output}
    """

rule check_combined_manifest:
    input:
        mf="collections/eukaryotes.mf.csv",
        links="collections/eukaryotes.links.csv",
    output:
        missing="collections/eukaryotes-missing.links.csv",
    shell: """
        scripts//compare-sigs-and-links.py --sigs {input.mf} --links {input.links} \
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
        "sketches/{NAME}.sig.zip",
    output:
        "downsampled/{NAME}.k51.s100_000.sig.zip",
    shell: """
        sourmash sig downsample -k 51 -s 100_000 {input} -o {output}
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

