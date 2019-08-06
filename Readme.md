# Targeted_RNAseq_Heatmap
This shiny app will let you create and download a house keeping normalized heatmap just by uploading RNAseq count X sample matrix.
The app is specific to targeted gene panels using housekeeping gene normalization. 
Displayed heatmap can be downloaded as PDF.

Link to app: https://svnallan.shinyapps.io/heatmaphknorm/

The input can be CSV format.

# Gene Annotations:
  Columns 1, 2 & 3 are for Gene annotations for all input files. 
    Column:1 - Amplicon ID (change column name to “AmpliconID”)
    Column:2 - Gene Symbol (change column name to “Gene”)
    Column:3 - Change this column name to “Function” for housekeeping normalization and text input for housekeeping genes should be “Housekeeping”. Third column can't be empty. At least enter housekeeping genes and label rest as “Unknown”.
    Second row for the first three columns should always be N/A.

# Sample annotations:
  Rows 3, 4 are for sample annotations (only 2 rows are allowed for now).
    Rows:3 & 4 for Columns: 1,2 should be N/A. Rows:3 & 4 for Column:3 should be annotation names e.g “GradeGroup”, “Patient.No”.
    Text input for sample annotations cannot include spaces, can take symbols. N/A if unknown.
