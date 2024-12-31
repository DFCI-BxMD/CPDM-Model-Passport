version 1.1

task cpdm_modelpassport {
  input {
    File sample_matrix
    String samplename
    File? cbio_profile = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-Gvk53f80YyvjBJYpfQ8994JP"
    File? str_profile = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-Gx3vFzj0YyvzFpFY106q39Qk"
    File? growth_matrix = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-GvyBkVj0Yyvzx8p5KyfKGFqj"
    File? model_image = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-GvyBkFQ0YyvvqG60qKGp7fgG"
  }

  parameter_meta {
    samplename: {
      label: "Sample Name"
    }
    sample_matrix: {
      label: "Sample Matrix",
      patterns: ["*.csv"]
    }
    cbio_profile: {
      label: "cBioPortal Profile",
      patterns: ["*.csv"]
    }    
    str_profile: {
      label: "STR Profile",
      patterns: ["*.csv"]
    }
    growth_matrix: {
      label: "Growth Curve",
      patterns: ["*.svg"]
    }
    model_image: {
      label: "Model TC Image",
      patterns: ["*.tif"]
    }
  }

  File rmarkdown = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-GxVKPGQ0YyvpzzZF6vYZJBKQ"


  String r_docker = "dx://file-Gk7yJYQ0V2Q4QJ803GXF16vy"
  #File no_tif = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-GvyBkFQ0YyvvqG60qKGp7fgG"
  #File no_svg = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-GvyBkVj0Yyvzx8p5KyfKGFqj" 
  File tier = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-Gvk4k480YyvxkG60jFYKB1v2"
  File interval_data = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-Gvk4k480Yyvgk3Jbp0yfjZ4k"
  File tcgainfo = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-Gvk4k480Yyvpv1F7KyVPpyfb"
  File tcga = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-Gvk4k480YyvQ5Yx98FQYV64F"
  File oncokb = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-Gvk4k480Yyvzyvz9GpyjB8Yg"

  File ensdb = "dx://project-Gvb6zBQ0YyvXz35byYpBX3zX:file-Gx6yjBQ0YyvVVgpqZk8QvgbY"

  command <<<
  set -euxo pipefail

# Install required libraries for ImageMagick, Chromium, and missing dependencies
apt-get update && apt-get install -y \
  imagemagick \
  libmagick++-dev \
  librsvg2-dev \
  libtiff-dev \
  gconf-service \
  libasound2 \
  libatk1.0-0 \
  libcairo2 \
  libcups2 \
  libfontconfig1 \
  libgdk-pixbuf2.0-0 \
  libgtk-3-0 \
  libnspr4 \
  libpango-1.0-0 \
  libxss1 \
  fonts-liberation \
  libappindicator1 \
  libnss3 \
  lsb-release \
  xdg-utils \
  wget


# Install TinyTeX (if not already installed)
R -e "if (!tinytex:::is_tinytex()) tinytex::install_tinytex()"

# Ensure LaTeX packages are installed
R -e "tinytex::tlmgr_install(c('xetex', 'fancyhdr', 'fontspec', 'geometry', 'titlesec', 'caption', 'underscore', 'floatrow', 'longtable'))"


# Update TinyTeX without 'repos' argument
 R -e "tinytex::tlmgr_update()"

# Install Chromium
wget -q -O google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb || true
apt-get install -f -y  # Fix any missing dependencies after dpkg install

# Set the CHROMOTE_CHROME environment variable for R
export CHROMOTE_CHROME=$(which google-chrome-stable)
google-chrome-stable --version

# Update ImageMagick policy for PDF processing
sed -i '/PDF/s/none/read|write/' /etc/ImageMagick-*/policy.xml

# Install preprocessCore with threading disabled
git clone https://github.com/bmbolstad/preprocessCore.git
cd preprocessCore
R CMD INSTALL --configure-args="--disable-threading" .

# Use the specified samplename to download the necessary files
sampleid=~{samplename}

source /home/dnanexus/environment

project_id=$(grep "project" /home/dnanexus/environment | awk -F "=" '{print $2}' | sed "s/'//g")

cd /home/dnanexus/work/
#####
echo "Processing sample ID: $sampleid"
#1
  file_id=$(dx find data --path $project_id:/ --name "${sampleid}*.genotypes.tsv" | grep -o "file-.*[^)]")
  if [ -z "$file_id" ]; then
    echo "Error: No file found for sample ID $sampleid"
    exit 1
  else
    dx download -f "${file_id}"
  fi

  
  file_id=$(dx find data --path $project_id:/ --name "${sampleid}*.quant.sf" | grep -o "file-.*[^)]")  
  if [ -z "$file_id" ]; then
    echo "Error: No quant.sf file found for sample ID $sampleid"
    exit 1
  fi
  dx download -f "${file_id}"
####

  file_id=$(dx find data --path $project_id:/ --name "*${sampleid}*.call.cns"  | grep -o "file-.*[^)]")
  if [ -z "$file_id" ]; then
    echo "Error: No .call.cns file found for sample ID $sampleid"
    exit 1
  fi
  dx download -f "${file_id}"


  file_id=$(dx find data --path $project_id:/ --name "*${sampleid}*.cnr" | grep -o "file-.*[^)]")
  if [ -z "$file_id" ]; then
    echo "Error: No .cnr file found for sample ID $sampleid"
    exit 1
  fi
  dx download -f "${file_id}"

  file_id=$(dx find data --path $project_id:/ --name "${sampleid}*.star-fusion.fusion_predictions.abridged.tsv" | grep -o "file-.*[^)]")
  if [ -z "$file_id" ]; then
    echo "Error: No .star-fusion.fusion_predictions.abridged.tsv file found for sample ID $sampleid"
    exit 1
  fi
  dx download -f "${file_id}"

  file_id=$(dx find data --path $project_id:/ --name "${sampleid}_*_gatk.oncoKB.maf" | grep -o "file-.*[^)]")
  if [ -z "$file_id" ]; then
    echo "Error: No gatk.oncoKB.maf file found for sample ID $sampleid"
    exit 1
  fi
  dx download -f "${file_id}"
##
  file_id=$(dx find data --path $project_id:/ --name "${sampleid}*.hg38_ReadsPerGene.out.tab" | grep -o "file-.*[^)]")
  if [ -z "$file_id" ]; then
    echo "Error: No hg38_ReadsPerGene.out.tab file found for sample ID $sampleid"
    exit 1
  fi
  dx download -f "${file_id}"
##

#### 
# Copy the sample matrix and R script
cp ~{sample_matrix} sample_matrix.csv
cp ~{cbio_profile} cBioPortal_links_for_patient_level_data.csv
cp ~{str_profile} STR_Profile_Data.csv
cp ~{rmarkdown} CPDM_ModelPassport_Report.Rmd
cp ~{tier} data_mutations_extended.txt
cp ~{interval_data} POPv3_AllTargetedRegions.interval_list
cp ~{tcgainfo} Celligner_info.csv
cp ~{tcga} TCGA_mat.tsv
cp ~{oncokb} oncoKB.csv
cp ~{growth_matrix} ~{samplename}_growth_ci_plot.svg 
cp ~{model_image} ~{samplename}_TQ.tif
#cp ~{model_image} ~{samplename}_data_TQ.tif
cp ~{ensdb} ensembl.hg38.csv


dx download project-Gvb6zBQ0YyvXz35byYpBX3zX:/dfci_logo3.jpg -o dfci_logo3.jpg

# Render the RMarkdown report
Rscript -e "rmarkdown::render('CPDM_ModelPassport_Report.Rmd',output_file = 'CPDM_ModelPassport_Report.~{samplename}.pdf', params = list(samplename='${sampleid}'))"

  >>>

  runtime {
    container: r_docker
    memory: "12G"
    dx_access: object {
      network: ["*"],
      project: "VIEW",
      allProjects: "VIEW"
    }
  }

  output {
    File report = "CPDM_ModelPassport_Report.~{samplename}.pdf"
  }
}
