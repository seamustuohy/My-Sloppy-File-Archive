#!/usr/bin/env bash
#
# Copyright © 2018 seamus tuohy, <code@seamustuohy.com>
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the included LICENSE file for details.

# Setup

#Bash should terminate in case a command or chain of command finishes with a non-zero exit status.
#Terminate the script in case an uninitialized variable is accessed.
#See: https://github.com/azet/community_bash_style_guide#style-conventions
set -e
set -u

# TODO remove DEBUGGING
# set -x

# Read Only variables

# readonly PROG_DIR=$(readlink -m $(dirname $0))
# readonly PROGNAME="$( cd "$( dirname "BASH_SOURCE[0]" )" && pwd )"
readonly metadata_file="_data/refs.yml"

readonly metadata_fields=( \
                           "title" \
                               "creation_date" \
                               "organization" \
)

readonly advanced_meta=( \
                         "description" \
                         "language" \
                         "publisher" \
    )

readonly resource_location=( \
                           "local_path" \
                           "live_url" \
                           "archive_url" \
    )

move_to_files() {
    filename=filename=$(basename -- "$1")
    extension="${filename##*.}"
    cp "$1" "files/${2}.${extension}"
    printf "files/${2}.${extension}"
}

main() {
    declare -A stored_metadata=()
    local shasum=$(sha256sum "$1" | cut -d ' ' -f 1)
    stored_metadata["hash"]="${shasum}"
    archive_filepath=$(move_to_files "$1" "${shasum}")
    stored_metadata["local_path"]="/${archive_filepath}"

    # NOTE: You will have to close the opened app later
    (go_go_xdg "$1" > /dev/null 2>&1 )&
    # Get filetype
    stored_metadata["form"]=$(file -b --mime-type "$1")
    for meta in "${metadata_fields[@]}"; do
        get_input
        stored_metadata["$meta"]="${TEMP_OUTPUT}"
    done

    # author_selector
    topic_selector
    stored_metadata["type"]="$TAG_STRING"

    # for i in "${!stored_metadata[@]}"
    # do
    #     echo "key  : $i"
    #     echo "value: ${stored_metadata[$i]}"
    # done

    # print_yml stored_metadata

    printf "\n\n" >> "${metadata_file}"
    local front_matter="- "
    for i in "${!stored_metadata[@]}"
    do
        printf "%s%s: %s\n" "${front_matter}" "$i" "${stored_metadata[$i]}" >> "${metadata_file}"
        # Change frontmatter to spaces after first time
        front_matter="  "
    done
}


get_input() {
    INPUT="UNKNOWN"
    TEMP_OUTPUT="UNKNOWN"
    PS3="Would you to type the ${meta} or paste it from the clipboard?"
    options=("clipboard" "type" "skip")
    select opt in "${options[@]}"; do
        case $opt in
            "clipboard")
                echo "Press ENTER when you have it copied..."
                read
                INPUT=$(xclip -o)
                clean_input
                break
                ;;
            "type")
                read -r INPUT
                clean_input
                break
                ;;
            "skip")
                INPUT="UNKNOWN"
                break
                ;;
        esac
    done
}


clean_input() {
    wo_spaces=$(echo "${INPUT}" \
                     | tr '[:cntrl:]' ' ' \
                     | tr -s ' ')
    lowercase=${wo_spaces,,}
    camel_case=$(to_camel "${lowercase}")
    TEMP_OUTPUT="${camel_case}"
}

to_camel() {
    IFS=" " read -ra str <<<"$1"
    printf '%s ' "${str[@]^}"
}


go_go_xdg() {
    # See possible appications
    # ls /usr/share/applications/
    #
    # Set new application for type
    # xdg-mime default [app.name] [mimetype]
    # i.e.
    # xdg-mime default google-chrome.desktop application/pdf

    xdg-open "$1"
}

final_tags="- title: %s \
  authors: %s \
  creation_date: %s \
  creator: %s \
  description: %s \
  form: %s \
  language: %s \
  live_url: %s \
  archive_url: %s \
  local_path: %s \
  organization: %s \
  publisher: %s \
  topics: %s \
  type: %s \
  year: %s "

topic_selector() {
    TAG_LIST=()
    PS3="Which tag would you like to add? (or EXIT)"
    options=(
            "EXIT"
        "reverse_engineering" \
            "osint" \
            "opsec" \
            "contingency_planning" \
            "threat_modeling" \
            "threat_intelligence" \
            "risk_management" \
            "privacy" \
            "incident_management" \
            "responsible_data" \
    )
    select opt in "${options[@]}"; do
        case $opt in
            "EXIT")
                echo "Done tagging"
                break
                ;;
            *)
                # Add the tag to the array of tags
                if containsElement "$opt" "${options[@]}" ; then
                    TAG_LIST+=("$opt")
                fi
                ;;
        esac
    done
    TAG_STRING=$(join_by , "${TAG_LIST[@]}")
    TAG_STRING=$(printf %s%s%s "[" "$TAG_STRING" "]")
}


join_by() {
    local IFS="$1";
    shift;
    echo "$*";
}

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

cleanup() {
    # put cleanup needs here
    exit 0
}

trap 'cleanup' EXIT

readonly PASSED="$1"
if [[ -d "$PASSED" ]]; then
    # Directory
    for i in "$PASSED"/*; do
        main "$i"
    done
elif [[ -f "$PASSED" ]]; then
    # File
    main "$PASSED"
else
    echo "Must pass path to directory or file to archive"
    echo "You passed us $PASSED which is neither"
    exit 1
fi
