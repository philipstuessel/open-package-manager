#!/bin/zsh
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
        folder_modules="$(pwd)/opm_modules/"
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
        urls=$(echo "$json_data" | jq -r '.scripts[]')
        while IFS= read -r urld; do
            directory=$(dirname "$urld")
            pack_folder="${folder_modules}/${package}/${directory}"
            mkdir -p "$pack_folder"
            script_url="${root}${urld}"
            echo -n "\r${BYELLOW}opm${NC} ${GREEN}$package${NC}"
            curl -o "${pack_folder}/$(basename "$urld")" $script_url > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo -ne "\r${BYELLOW}opm${NC} ${GREEN}$package${NC} $urld : bulk request"
                echo -ne "\033[K" 
            else
                echo -e "${RED}ERROR occurred with $script_url${NC}"
                echo -ne "\033[K" 
            fi
        done <<< "$urls"
        echo -ne "\r${BBLUE}opm${NC} ${GREEN}$package${NC} Was add to (opm_modules)"
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
        file=$(opm_dep)
        if jq ".dependencies | index(\"$package\")" "$file" | grep -q "null"; then
            jq ".dependencies += [\"$package\"]" "$file" > tmp_config.json
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
  "license": "MIT",
  "repository": {
    "type": "",
    "url": ""
  },
  "root": "",
  "scripts": ""
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
    "dependencies": [],
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
        echo -e "${BOLD}v.0.3.0${NC}"
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