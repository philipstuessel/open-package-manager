#!/bin/zsh
opm_check() {
    if [ ! -f "$(pwd)/dependency.json" ]; then
        echo "${RED}dependency.json File not found${NC}"
        return 0
    fi
    return 1
}

opm_config() {
    CONFIG_FILE="/Users/$USER/jap/config/opm.config.json"

    if [ -e "${CONFIG_FILE}" ]; then
        if [[ "$1" == "roots" ]]; then
            jq -r '.roots[]' ${CONFIG_FILE} | while read -r line; do
                echo ${BLUE}-${NC} "${YELLOW}$line${NC}"
            done
        fi
        if [[ "$1" == "t" ]];then
            q="$2" 
            urls=$(jq -r '.roots[]' "$CONFIG_FILE")
            while IFS= read -r url; do
	            json_data=$(curl -s "$url")
	            key_value=$(echo "$json_data" | jq -r ".\"$q\"")
	            if [[ ! $key_value == null ]];then
		            echo $key_value;
            		return 1
	            fi
            done <<< "$urls"
            echo "${RED}No package with the name '$q' was found${NC}"
            return 0
        elif [[ "$1" == "l" ]];then
            urls=$(jq -r '.roots[]' "$CONFIG_FILE")
            while IFS= read -r url; do
                echo "------------------------------------"
                echo "${YELLOW}$url${NC}"
	            json_data=$(curl -s "$url")
	            keys=$(echo "$json_data" | jq -r 'keys[]')
                echo "${BOLD}$keys${NC}"
            done <<< "$urls"
            echo "------------------------------------"
            return 0
        fi
    else
        echo -e "${RED}Config file not found${NC}"
        return 0
    fi
}

opm_core() {
    if [[ -z "$2" ]]; then
        DIR=$(pwd)
    else
        if [ ! -d "$2" ]; then
            mkdir -p "$2"
        fi
        DIR="$2"
    fi

    file="$1";
    if [[ ! -L "$1" && ! -f "$1" ]]; then
        file=$(opm_config "t" "$1");
        if [[ $? == 0 ]]; then
            echo $file
            return 0
        fi
    fi

    if [[ -e $file ]]; then
        cp "${$file}" ${DIR}/"$(basename "${$file}")" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "🚛 ${UNDERLINE}${$file}${NC} ${MAGENTA}->${NC} ${DIR}"
        else
            echo "🚚 ${RED}${$file}${NC} ${MAGENTA}->${NC} ${DIR}"
        fi
    else
        curl -o "${DIR}/$(basename "$file")" "$file" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "🚛 ${UNDERLINE}$file${NC} ${MAGENTA}->${NC} ${DIR}"
        else
            echo "🚚 ${RED}$file${NC} ${MAGENTA}->${NC} ${DIR}"
        fi
    fi
}

opm() {
    if [[ "$1" == "v" || "$1" == "-v" ]]; then
        echo "${BLUE}Open Package Manager (OPM)${NC}"
        echo "${BOLD}v.0.1.1${NC}"
        echo "${YELLOW}JAP plugin${NC}"
        elif [[ "$1" == "i" || "$1" == "install" ]]; then
            opm_check
            if [[ $? == 0 ]]; then
                return 0
            fi
            json=$(cat dependency.json)
            urls=$(echo "$json" | jq -r 'to_entries[] | .key + " " + .value')
            
            while IFS= read -r url; do
                key=$(echo "$url" | cut -d ' ' -f 1)
                value=$(echo "$url" | cut -d ' ' -f 2)
                opm_core $key $value
            done <<< "$urls"
            elif [[ "$1" == "l" || "$1" == "list" ]];then
                opm_config "l"
            elif [[ "$1" == "roots" ]];then
                opm_config "$1"
    else
        opm_core "$1" "$2"
    fi
}