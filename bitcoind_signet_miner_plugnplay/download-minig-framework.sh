#!/bin/bash

# Set the GitHub repository and subfolder
repo="bitcoin/bitcoin"
subfolder="test/functional/test_framework"
branch="v${BITCOIND_VER}"

# Set the default output directory to the current directory
output_dir="/bitcoind"

# parse command line options
while getopts ":r:s:b:d:" opt; do
    case ${opt} in
        r ) repo="$OPTARG"
        ;;
        b ) branch="$OPTARG"
        ;;
        s ) subfolder="$OPTARG"
        ;;
        d ) output_dir="$OPTARG"
        ;;
        \? ) echo "Usage: download_repo.sh [-r <repo>] [-s <subfolder>] [-b <branch>] [-d <dest_folder>]"
            echo "Using default values:"
            echo "Repository: $repo"
            echo "Subfolder: $subfolder"
            echo "Branch: $branch"
            echo "Destination folder: $output_dir"
            exit 1
        ;;
    esac
done
shift $((OPTIND -1))

# Download all files in the subfolder
download_files() {
    curl -s "https://api.github.com/repos/$repo/contents/$3?ref=$2" |
    jq -r '.[] | select(.type == "dir").path' |
    while read dir; do
        download_files "$repo" "$branch" "$dir" "$4"
    done

    curl -s "https://api.github.com/repos/$repo/contents/$3?ref=$2" |
    jq -r '.[] | select(.type == "file").path' |
    while read path; do
        url="https://raw.githubusercontent.com/$repo/$branch/$path"
        mkdir -p "$4/$(dirname $path)"
        curl -L -o "$4/$path" "$url"
    done
}

# Call the function to download all files in the subfolder
download_files "$repo" "$branch" "$subfolder" "$output_dir"
