source ~/.zshrc
name="opm"
url=https://raw.githubusercontent.com/philipstuessel/open-package-manager/main/
folder="${JAP_FOLDER}plugins/packages/${name}/"
folder_config="${folder}config/"
fetch2 $folder "${url}opm.zsh"
fetch2 $folder "${url}opd.zsh"
fetch2 $folder_config "${url}config/opm.config.json"
fetch2 $folder_config "${url}config/roots.json"
echo "--OPM is installed--"