#!/usr/bin/zsh

#
# This file contains the obfuscator module
# It is *technically* an encryption module with a couple of keys (alphabets)
# It is **NOT** recommanded for external usage, this module was mostly made for fun and remains
# weaker than standard AES (among other algorithms).
#

# Input alphabet location
export ADF_OBF_INPUT_ALPHABET_FILE="$ADF_DATA_DIR/adf-obfuscator-alphabet.input.txt"
export ADF_OBF_OUTPUT_ALPHABET_FILE="$ADF_DATA_DIR/adf-obfuscator-alphabet.output.txt"

# Generate a random alphabet
function adf_obf_gen_alphabet() {
    local str="$(awk 'BEGIN{for(i=32;i<128;i++)printf "%c\n",i; print}')$(awk 'BEGIN{for(i=160;i<255;i++)printf "%c\n",i; print}')"
    local shuffled=$(printf '%s' "$str" | sort -R)
    local alphabet_no_nl=${(j::)${(@f)shuffled}}

    local nl_index=$(( (RANDOM % 189) + 1 ))
    local nl=$'\n'
    local alphabet="${alphabet_no_nl:0:$nl_index}$nl${alphabet_no_nl:$nl_index}"

    if [[ ${#alphabet} != 192 ]]; then
        echoerr "Internal: invalid alphabet length (${#alphabet})"
        echodata "$alphabet"
        return 1
    fi

    printf '%s' "$(printf '%s' "$alphabet" | base64 -w0)"
}

# Ensure the random alphabets exist locally
function adf_obf_init_alphabets() {
    if [[ ! -f "$ADF_OBF_INPUT_ALPHABET_FILE" || $1 == "--regen" ]]; then
        echoinfo "Generating input alphabet..."

        if ! adf_obf_gen_alphabet > "$ADF_OBF_INPUT_ALPHABET_FILE"; then
            echoerr "Internal: failed to generate the input alphabet."
            return 1
        fi
    fi

    if [[ ! -f "$ADF_OBF_OUTPUT_ALPHABET_FILE" || $1 == "--regen" ]]; then
        echoinfo "Generating output alphabet..."
    
        if ! adf_obf_gen_alphabet > "$ADF_OBF_OUTPUT_ALPHABET_FILE"; then
            echoerr "Internal: failed to generate the output alphabet."
            return 2
        fi
    fi

    echoinfo "Loading alphabets from disk..."

    export __ADF_OBF_INPUT_ALPHABET=$(base64 -d -w0 "$ADF_OBF_INPUT_ALPHABET_FILE")
    export __ADF_OBF_OUTPUT_ALPHABET=$(base64 -d -w0 "$ADF_OBF_OUTPUT_ALPHABET_FILE")

    echosuccess "Done."
}

# Display the current input alphabet
function adf_obf_current_input_alphabet() {
    if ! ADF_SILENT=1 adf_obf_init_alphabets; then return 1; fi

    printf '%s' "$__ADF_OBF_INPUT_ALPHABET"
}

# Display the current output alphabet
function adf_obf_current_output_alphabet() {
    if ! ADF_SILENT=1 adf_obf_init_alphabets; then return 1; fi

    printf '%s' "$__ADF_OBF_OUTPUT_ALPHABET"
}

# Hash a message to check its integrity during decoding
# or to check if it has been decoded correctly
function adf_obf_checksum() {
    printf '%s' "$1" | cksum | cksum | xargs printf '%0X'
}

# Validate the checksum of a message
function adf_obf_validate_checksum() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide a message with its checksum to decode."
        return 1
    fi

    if [[ ! $1 =~ ^([0-9A-F]+):(.*)$ ]]; then
        echoerr "Checksum is missing from the provided message: \z[cyan]°$1\z[]°"
        return 2
    fi

    local got_checksum="${match[1]}"
    local message="${match[2]}"
    
    local msg_checksum=$(adf_obf_checksum "$message")

    if [[ $got_checksum != $msg_checksum ]]; then
        echoerr "Invalid checksum found: expected \z[yellow]°$msg_checksum\z[]°, found \z[yellow]°$got_checksum\z[]° in message: \z[cyan]°$1\z[]°"
        return 3
    fi

    printf "%s" "$message"
}

# Transform (obfuscate / unobfuscate) a string
# Usage: "adf_obf_transform <message> <input alphabet> <output alphabet> <encode = 0, decode = 1>"
function adf_obf_transform() {    
    if [[ -z $2 ]]; then
        echoerr "Please provide an input alphabet."
        echoerr "Usage: $0 <message> <input alphabet> <output alphabet> <encode = 0 / decode = 1>"
        return 1
    fi

    if [[ -z $3 ]]; then
        echoerr "Please provide an output alphabet."
        echoerr "Usage: $0 <message> <input alphabet> <output alphabet> <encode = 0 / decode = 1>"
        return 1
    fi

    if [[ -z $4 ]] || [[ $4 != 0 && $4 != 1 ]]; then
        echoerr "Please provide a valide encoding (0) or decoding (1) mode."
        echoerr "Usage: $0 <message> <input alphabet> <output alphabet> <encode = 0 / decode = 1>"
        return 1
    fi

    if [[ ${#2} != 192 ]]; then
        echoerr "Input alphabet is not 192 characters long."
        return 2
    fi

    if [[ ${#3} != 192 ]]; then
        echoerr "Output alphabet is not 192 characters long."
        return 2
    fi

    if [[ $4 == 0 ]]; then
        local is_encoding=1
        local base_alphabet="$2"
        local converted_alphabet="$3"
        local fail_word="encode"
        local shift_multiplier=1
    else
        local is_encoding=0
        local base_alphabet="$3"
        local converted_alphabet="$2"
        local fail_word="decode"
        local shift_multiplier=-1
    fi

    local raw_input=""

    if [[ -z "$1" ]]; then
        raw_input=$(printf "%s" "$(</dev/stdin)")
    else
        if (( $is_encoding )) && ! (( $OBF_ARG_SAFE )); then
            echowarn "ENSURE TO NOT PROVIDE ANY SENSITIVE DATA AS AN ARGUMENT!"
        fi

        raw_input="$1"
    fi

    if [[ $is_encoding = 0 && -z "$OBF_NO_BASE64" ]]; then
        if ! input="$(printf '%s' "$raw_input" | base64 -d -w0)"; then
            echoerr "Failed to decode input: invalid base64 provided"
            return 1
        fi
    else
        input="$raw_input"
    fi

    if [[ -z $input && ! -z $OBF_NO_CHECKSUM ]]; then
        echoerr "Input cannot be empty as it should contain its own checksum."
        return 1
    fi

    if [[ $is_encoding = 1 && -z $OBF_NO_CHECKSUM ]]; then
        input="$(adf_obf_checksum "$input"):$input"
    fi

    local out=()

    converted_alphabet="$converted_alphabet$converted_alphabet$converted_alphabet"

    for i in {1..${#input}}; do
        local char=${input[i]}

        >&2 echoverb "Character: \z[cyan]°>$char< \z[green]°(0x$(printf '%x\n' "'$char'"))\z[]°\z[]°"

        local index=${base_alphabet[(ie)$char]}

        if [[ $index == 0 || $index -gt ${#base_alphabet} ]]; then
            echoerr "Failed to $fail_word character >\z[yellow]°$char\z[]°<: unknown character"
            return 2
        fi

        if [[ -z $OBF_NO_SHIFT ]]; then
            if (( i % 3 >= ${#input} % 3 )) || (( i % 4 == ${#input} % 4 )); then
                local shift=$((floor((exp(i) + ${#input}) % 100)))
                index=$((index + (${shift%.} * shift_multiplier)))
            fi
        fi

        local outchar="${converted_alphabet[$index+192]}"

        >&2 echoverb "Converted to: \z[yellow]°>$outchar<\z[]° \z[green]°(0x$(printf '%x\n' "'$outchar'"))\z[]°"

        out+=("$outchar")
    done

    local output=${(j::)out}

    if [[ ${#input} != ${#output} ]]; then
        echoerr "Internal: output (\z[yellow]°${#output}\z[]° characters) has not the same length than input (\z[yellow]°${#input}\z[]°)"
        return 3
    fi

    if [[ $is_encoding = 0 && -z $OBF_NO_CHECKSUM ]]; then
        output=$(adf_obf_validate_checksum "$output")

        if [[ $? != 0 ]]; then
            return 3
        fi
    fi

    if [[ $is_encoding = 1 && -z $OBF_NO_BASE64 ]]; then
        output="$(printf '%s' "$output" | base64 -w0)"
    fi

    printf '%s' "$output"
}

# Obfuscate a string
# Useful for storing mildly-sensitive data in source codes
# The local alphabet is used
function adf_obf_encode() {
    if ! ADF_SILENT=1 adf_obf_init_alphabets; then return 1; fi
    adf_obf_transform "$1" "$__ADF_OBF_INPUT_ALPHABET" "$__ADF_OBF_OUTPUT_ALPHABET" 0
}

# Obfuscate a string from a user prompt
function adf_obf_encode_prompt() {
    prompt -s "Please write the plain message: " | adf_obf_encode
}

# Unobfuscate a string generated by the obfuscation function
# The local alphabet is used
function adf_obf_decode() {
    if ! ADF_SILENT=1 adf_obf_init_alphabets; then return 1; fi
    adf_obf_transform "$1" "$__ADF_OBF_INPUT_ALPHABET" "$__ADF_OBF_OUTPUT_ALPHABET" 1
}

# Obfuscate a string from a user prompt
function adf_obf_decode_prompt() {
    prompt -s "Please write the encoded message: " | adf_obf_decode
}

# Obfuscate and then unobfuscate a string, to ensure obfuscation works correctly
# The local alphabet is used
function adf_obf_test() {
    if ! ADF_SILENT=1 adf_obf_init_alphabets; then return 1; fi

    local input="$(</dev/stdin)"

    echoinfo "Plain (input) =\n\n\z[yellow]°%s\z[]°" "$input"

    echoverb "Encoding the message..."
    if ! encoded=$(printf '%s' "$input" | adf_obf_encode); then
        return 2
    fi

    if [[ -z $OBF_NO_INTERMEDIARY_TEST_DATA ]]; then
        echoinfo "\nEncoded (obfuscated) =\n\n\z[yellow]°%s\z[]°\n" "$encoded"

        if [[ -z "$OBF_NO_BASE64" ]]; then
            echoinfo "Encoded (base64 decoded) =\n\n\z[yellow]°%s\z[]°\n" "$(printf '%s' "$encoded" | base64 -d -w0)"
        fi
    fi

    echoverb "Decoding the encoded message..."
    if ! decoded=$(printf '%s' "$encoded" | adf_obf_decode); then
        return 3
    fi

    echoinfo "\nDecoded (output) =\n\n\z[yellow]°%s\z[]°\n" "$decoded"

    echoverb "Comparing...\n"

    if [[ $input != $decoded ]]; then
        echoerr "Input and output are not the same! Seems like an internal problem."
        return 4
    fi

    echosuccess "Message was successfully encoded and decoded."
}

# Run a test with the full current alphabets,
# to test if all characters can be encoded and decoded correctly
function adf_obf_test_current_alphabets() {
    if ! ADF_SILENT=1 adf_obf_init_alphabets; then return 1; fi

    if ! adf_obf_current_input_alphabet | adf_obf_test; then
        return 2
    fi

    echoinfo ""

    if ! adf_obf_current_output_alphabet | adf_obf_test; then
        return 3
    fi
}
