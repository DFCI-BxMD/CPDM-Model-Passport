# CPDM ModelPassport

## What does this app do?

The CPDM ModelPassport application generates a comprehensive report that provides details about the model's clinical properties integrated with genomic features. 

## What are the inputs?

- ```Sample Matrix```: Sample Matrix Files (```Comma separated table with any features clinical and model properties.  *.csv```). 
- ```Sample Name```: Sample Name (```The name of the "CPDM ID" for which the reads come from.```).
- ```cBioPortal Profile```: Input cBioPortal Profile table (```"*.csv"```), and input table should include the following column:(```"CPDM_ID"```and ```"link"```),.
- ```STR Profile```:  Input STR Profile table (```"*.csv"```).
- ```growth_matrix```:  Input Growth Curve (```"*.svg"```).
- ```model_image```:  Input Model TC Image (```"*.tif"```).


## What are the outputs?

The output is an PDF report that Includes the following components in report:

- ```Model and Clinical Properties```: Summarized tables.  
- ```STR profiling and HLA typing```: include STR profile and HLA-typing tables.   
- ```Visualizations and Advanced Analyses```:  
  - Correlation to TCGA samples.  
  - Small Nucleotide Variants
  - Copy number variation (CNV) profiles.  
  - Gene fusion analysis: Circos plot and table. 

  ```
  {
  "CPDM_ModelPassport_Report.~{samplename}.pdf",
  }