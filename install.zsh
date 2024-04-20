source ~/.zshrc
name="opm"
folder="${JAP_FOLDER}plugins/packages/${name}/"
folder_config="${folder}config/"
fetch2 $folder https://raw.githubusercontent.com/philipstuessel/open-package-manager/main/opm.zsh
fetch2 $folder_config https://raw.githubusercontent.com/philipstuessel/open-package-manager/main/config/opm.config.json
fetch2 $folder_config https://raw.githubusercontent.com/philipstuessel/open-package-manager/main/config/roots.json
echo "--OPM is installed--"