#!/bin/zsh
if command -v jq &> /dev/null; then
    echo ""
else
    brew install jq
fi

source ~/.zshrc
fetch ~/jap/plugins/packages/ ~/jap/plugins/packages/opm.zsh https://raw.githubusercontent.com/philipstuessel/open-package-manager/main/opm.zsh
echo "--OPM is installed--"