#!/bin/zsh
opd() {
    if [[ "$1" == "v" || "$1" == "-v" ]]; then
        echo -e "${BLUE}Open Package Developers (OPD)${NC}"
        echo -e "${BOLD}v0.1.1${NC}"
        echo -e "${CYAN}comes with OPM${NC}"
    fi

    if [[ "$1" == "min" ]]; then
        min "$2" "$3"
    fi
}

min() {
    dir="$1"
    output_dir="$2"

    if [[ "$2" == "" ]];then
        output_dir=$dir
    fi

    mkdir -p "$output_dir"

    if [ ! -d "$dir" ]; then
        echo "Directory '$dir' not found."
        return 1
    fi

    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
    fi

    for file in "$dir"/*; do
        if [[ "$file" == *.js ]]; then
            minify_js "$file"
        elif [[ "$file" == *.css ]]; then
            minify_css "$file"
        fi
    done

    echo "${GREEN}Minification completed.${NC}"
}

minify_js() {
    local file="$1"
    local filename=$(basename -- "$file")
    
    if [[ "$filename" != *.min.js ]]; then
        local output_file="$output_dir/${filename%.*}.min.js"
        
        local input_content=$(cat "$file")
        curl -X POST -s --data-urlencode "input=$input_content" "https://www.toptal.com/developers/javascript-minifier/api/raw" -o "$output_file"
        echo "${YELLOW}Minimized: $filename -> $output_file${NC}"
    fi
}

minify_css() {
    local file="$1"
    local filename=$(basename -- "$file")
    
    if [[ "$filename" != *.min.css ]]; then
        local output_file="$output_dir/${filename%.*}.min.css" 
        cat "$file" | tr -d '\n' | tr -d '[:space:]' > "$output_file"
        echo "${YELLOW}Minimized: $filename -> $output_file${NC}"
    fi
}