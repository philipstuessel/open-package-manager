#!/bin/zsh
source $JAP_FOLDER/plugins/packages/opm/opd.zsh
MAIN_FOLDER="${JAP_FOLDER}plugins/packages/opm/config/"
CONFIG_FILE="${MAIN_FOLDER}opm.config.json"
ROOTS_FILE="${MAIN_FOLDER}roots.json"

opm_check() {
    if [ ! -f "$(pwd)/dependency.json" ]; then
        echo -e "${RED}dependency.json File not found${NC}"
        return 0
    fi
    return 1
}

opm_config() {
    if [ -e "${CONFIG_FILE}" ]; then
        if [[ "$1" == "roots" ]]; then # list roots
            jq -r '.roots[]' ${ROOTS_FILE} | while read -r line; do
                echo -e ${BLUE}-${NC} "${YELLOW}$line${NC}"
            done
        fi
        if [[ "$1" == "t" ]];then # test is pag
            q="$2"
            urls=$(jq -r '.roots[]' "$ROOTS_FILE")
            while IFS= read -r url; do
                json_data=$(curl -s "$url")
                jq_output=$(echo "$json_data" | jq -r "to_entries[] | select(.key == \"$q\") | .key + \" \" + (.value | tostring)")
                if [[ ! $jq_output == "" ]]; then
                    echo $jq_output $url
                    return 1;
                fi
            done <<< "$urls"
            echo -e "${RED}No package found with the name '$q'${NC}"
            return 0
        elif [[ "$1" == "l" ]];then # list roots the keys
            urls=$(jq -r '.roots[]' "$ROOTS_FILE")
            while IFS= read -r url; do
                echo "------------------------------------"
                echo -e "${YELLOW}$url${NC}"
	            json_data=$(curl -s "$url")
	            keys=$(echo "$json_data" | jq -r 'keys[]')
                echo -e "${BOLD}$keys${NC}"
            done <<< "$urls"
            echo "------------------------------------"
            return 0
        elif [[ "$1" == "sr" ]];then # get modules
            sr=$(jq -r '.saveRoots == true' "$CONFIG_FILE")
            if [[ ! $sr ]];then 
                return 0
            else
                return 1
            fi
        elif [[ "$1" == "ar" ]]; then # add a url in json file
            url="$2";
            file="$3";
            first="root"
            if [[ "$3" == "r" ]];then # add in roots
                file=$ROOTS_FILE;
                first="${BYELLOW}root${NC}"
            fi
            if jq ".roots | index(\"$url\")" "$file" | grep -q "null"; then
                    jq ".roots += [\"$url\"]" "$file" > tmp_config.json
                    mv tmp_config.json "$file"
                    filename=$(basename "$file")
                    echo -e "$first: ${BOLD}$url${NC} was added to $filename";
            fi
        fi
    else
        echo -e "${RED}Config file not found${NC}"
        return 0
    fi
}

opm_core() {
    if [[ "$1" == "s" ]]; then
        package="$2"
        script="$3"
        folder_modules="$(pwd)/opm_modules"
        script_folder="$folder_modules/$package"
        if [ ! -d "$script_folder" ]; then
            mkdir "$script_folder"
        fi
        curl -o "${script_folder}/$(basename "$script")" "$script" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
                echo -e "${BBLUE}opm${NC} ${GREEN}$package${NC} Was add to (opm_modules)"
            else
                echo -e "${BRED}opm${NC} ${RED}ERROR occurred with $package${NC}"
        fi
    fi
    if [[ "$1" == "zip" ]];then
        package="$2"
        script="$3"
        folder_modules="$(pwd)/opm_modules"
        script_folder="$folder_modules/$package"
        if [ ! -d "$script_folder" ]; then
            mkdir "$script_folder"
        fi
        if [[ "$4" == "api_github" ]];then
            echo -n "${BYELLOW}opm${NC} ${GREEN}$package${NC} download start in (opm_modules)"
            rm -rf "$script_folder"
            curl -L $script -o "${folder_modules}/$5.zip" >/dev/null 2>&1
            if [ ! $? -eq 0 ]; then
                echo -e "${BRED}opm${NC} ${RED}ERROR occurred with $package${NC}"
            fi
            unzip "${folder_modules}/$5.zip" -d $folder_modules >/dev/null 2>&1
            rm "${folder_modules}/$5.zip"
            mv "${folder_modules}/$5" $script_folder
            if [ $? -eq 0 ]; then
                echo -ne "\r${BBLUE}opm${NC} ${GREEN}$package${NC} Was add to (opm_modules)"
            else
                echo -ne "\r${BRED}opm${NC} ${RED}ERROR occurred with $package${NC}"
            fi
            return 1
        fi
        curl -L $script -o "${script_folder}/$(basename "$script")" >/dev/null 2>&1
        if [ ! $? -eq 0 ]; then
            echo -e "${BRED}opm${NC} ${RED}ERROR occurred with $package${NC}"
        fi
        unzip "${script_folder}/$(basename "$script")" -d $script_folder >/dev/null 2>&1
        rm "${script_folder}/$(basename "$script")"
        if [ $? -eq 0 ]; then
            echo -e "${BBLUE}opm${NC} ${GREEN}$package${NC} Was add to (opm_modules)"
        else
            echo -e "${BRED}opm${NC} ${RED}ERROR occurred with $package${NC}"
        fi
    fi

if [[ "$1" == "d" ]];then 
    script="$3"
    json_data=$(curl -s "$script")
    package=$(echo "$json_data" | jq '.name' | sed 's/^"\(.*\)"$/\1/')
    folder_modules="$(pwd)/opm_modules/"
    package_folder="$folder_modules$package"
    if [ ! -d "$package_folder" ]; then
        mkdir "$package_folder"
    fi
    root=$(echo "$json_data" | jq '.root' | sed 's/^"\(.*\)"$/\1/')
    filename=$(basename "$root")
    file_extension=$(echo "$filename" | awk -F . '{print $NF}')
    if [[ $file_extension == "zip" || $file_extension == "gzip" ]]; then
        opm_core "zip" $package $root
        return 0
    elif [[ $root == "api.github" ]];then
        API_GITHUB="https://api.github.com/repos/"
        git_url=$(echo "$json_data" | jq -r '.repository.url')
        sha=$(echo "$json_data" | jq -r '.repository.sha')
        author=$(echo $git_url | awk -F'/' '{print $4}')
        repo=$(echo $git_url | awk -F'/' '{print $5}')
        zip_url="${API_GITHUB}${author}/${author}/zipball/${sha}"
        zip_name="${author}-${author}-$(echo $sha | cut -c 1-7)"
        opm_core "zip" $package $zip_url "api_github" $zip_name
        return 0
    else
    urlsd=$(echo "$json_data" | jq -r '.scripts[]')
    echo -n "\r${BYELLOW}opm${NC} ${GREEN}$package${NC}"
    while IFS= read -r urld; do
        directory=$(dirname "$urld")
        pack_folder="${folder_modules}/${package}/${directory}"
        mkdir -p "$pack_folder"
        script_url="${root}${urld}"
        curl -o "${pack_folder}/$(basename "$urld")" $script_url > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -ne "\r\033[K${BYELLOW}opm${NC} ${GREEN}$package${NC} $urld : bulk request"
        else
            echo -e "\r\033[K${RED}ERROR occurred with $script_url${NC}"
        fi
    done <<< "$urlsd"
        echo -e "\r\033[K${BBLUE}opm${NC} ${GREEN}$package${NC} Was add to (opm_modules)"
    fi
fi
}

opm_core_modules() {
    if [[ "$1" == "sadd" ]]; then # add script in dep
        package="$2"
        script="$3"
        file=$(opm_dep)
        if jq ".scripts | index(\"$package\")" "$file" | grep -q "null"; then
            jq ".scripts += [\"$package\"]" "$file" > tmp_config.json
            mv tmp_config.json "$file"
            echo -e "dependency: ${BOLD}$package${NC} was added to dependency";
        fi
        opm_core "s" $package $script
    fi 
    if [[ "$1" == "dadd" ]];then # add package in dep
        package="$2"
        script="$3"
        json_data=$(curl -s "$script")
        version=$(echo "$json_data" | jq '.version' | sed 's/^"\(.*\)"$/\1/')
        file=$(opm_dep)
        if jq ".dependencies | has(\"$package\")" "$file" | grep -q "false"; then
            jq ".dependencies += {\"$package\": \"$version\"}" "$file" > tmp_config.json
            mv tmp_config.json "$file"
            echo -e "dependency: ${BOLD}$package${NC} was added to dependency";
        fi
        opm_core "d" $package $script
    fi
}

opm_modules() {
    if [[ "$1" == "add" ]]; then
        file=$(opm_config "t" "$2");
        if [[ $? == 0 ]]; then
            echo $file;
            return 0;
        fi
        opm_setup
        
        package=$(echo $file | awk '{print $1}')
        script=$(echo $file | awk '{print $2}')
        url=$(echo $file | awk '{print $3}')
        opm_config "ar" $url $(opm_dep)
        if [[ "$(basename "$script")" == "dependency-map.json" ]]; then
            opm_core_modules "dadd" $package $script
            return 0;
        else
            opm_core_modules "sadd" $package $script
        fi
    elif [[ "$1" == "i" ]]; then
        dep=$(opm_dep)
        urls=$(jq -r '.roots[]' "$dep")
        scripts=$(jq -r '.scripts[]' "$dep")
        sr=$(jq -r '.saveRoots == true' "$CONFIG_FILE")
        while IFS= read -r pack; do
            while IFS= read -r url; do
                json_data=$(curl -s "$url")
                jq_output=$(echo "$json_data" | jq -r "to_entries[] | select(.key == \"$pack\") | .key + \" \" + (.value | tostring)")
                if [[ ! $jq_output == "" ]]; then
                    package=$(echo $jq_output | awk '{print $1}')
                    script=$(echo $jq_output | awk '{print $2}')
                    opm_core "s" $package $script
                fi
                if [[ $sr == true ]]; then
                    opm_config "ar" $url "r"
                fi
            done <<< "$urls"
        done <<< "$scripts"
        dependencies=$(jq -r '.dependencies[]' "$dep")
        while IFS= read -r pack; do
            while IFS= read -r url; do
                json_data=$(curl -s "$url")
                jq_output=$(echo "$json_data" | jq -r "to_entries[] | select(.key == \"$pack\") | .key + \" \" + (.value | tostring)")
                if [[ ! $jq_output == "" ]]; then
                    package=$(echo $jq_output | awk '{print $1}')
                    script=$(echo $jq_output | awk '{print $2}')
                    opm_core_modules "dadd" $package $script
                fi
            done <<< "$urls"
        done <<< "$dependencies"
    fi
}

opm_dep() {
    echo "$(pwd)/dependency.json";
}

opm_setup() {
if [[ "$1" == "c" ]];then
content='{
  "name": "",
  "version": "",
  "description": "",
  "homepage": "",
  "author": "",
  "license": "",
  "repository": {
    "type": "",
    "url": "",
    "sha": ""
  },
  "root": "",
  "scripts": []
}'
    json_file="dependency-map.json"
    if [ ! -f "$json_file" ]; then
        echo "$content" > "$json_file"
    fi
        return 0;
    fi
folder="opm_modules"
json_file=$(opm_dep)
content='{
"name": "Project",
"version": "1.0.0",
"description": "",
    "scripts": [],
    "dependencies": {},
    "roots": []
}';
    if [ ! -d "$folder" ]; then
        mkdir "$folder"
    fi

    if [ ! -f "$json_file" ]; then
        echo "$content" > "$json_file"
    fi
}

opm() {
    if [[ "$1" == "v" || "$1" == "-v" ]]; then
        echo -e "${BLUE}Open Package Manager (OPM)${NC}"
        echo -e "${BOLD}v0.4.0${NC}"
        echo -e "${YELLOW}JAP plugin${NC}"
    elif [[ "$1" == "i" || "$1" == "install" ]]; then
            if [[ ! "$2" == "" ]];then
                opm_modules "add" "$2"
                return 0
            else
                check=$(opm_check)
                if [[ $? == 0 ]]; then
                    echo $check
                    return 0
                fi
                opm_setup
                opm_modules "i"
            fi
    elif [[ "$1" == "r" ]]; then
        if [[ "$2" == "root" ]];then
            jq --arg link "$3" '.roots |= map(select(. != $link))' "$ROOTS_FILE" > temp.json && mv temp.json "$ROOTS_FILE"
            echo -e "${YELLOW}The root '$3' was deleted from the local roots${NC}"
        fi
    elif [[ "$1" == "l" || "$1" == "list" ]];then
            opm_config "l"
    elif [[ "$1" == "roots" ]];then
            opm_config "$1"
    elif [[ "$1" == "map" ]];then
        file=$(opm_config "t" "$2");
        if [[ $? == 0 ]]; then
            echo $file;
            return 0;
        fi
        script=$(echo $file | awk '{print $2}')
        if [[ "$(basename "$script")" == "dependency-map.json" ]]; then
            echo "map url: "$script
            curl -s $script | jq '.'
        else
            echo -e "${RED}The '$2' is not a dependency package${NC}"
        fi
    elif [[ "$1" == "c" || "$1" == "create" ]];then
        opm_setup "c"
        echo "${GREEN}craete 'dependency-map.json' in $(pwd) ${NC}"
    fi

    if [[ "$1" == "add" ]];then
        opm_config "ar" "$2" "r"
    fi
}