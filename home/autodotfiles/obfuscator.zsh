#!/usr/bin/zsh

#
# This file contains the obfuscator module
#

# Input alphabet location
export ADF_OBF_INPUT_ALPHABET_FILE="$ADF_DATA_DIR/adf-obfuscator-alphabet.input.txt"
export ADF_OBF_OUTPUT_ALPHABET_FILE="$ADF_DATA_DIR/adf-obfuscator-alphabet.output.txt"

# Generate a random alphabet
function adf_obf_gen_alphabet() {
    local str="$(awk 'BEGIN{for(i=32;i<128;i++)printf "%c\n",i; print}')$(awk 'BEGIN{for(i=160;i<255;i++)printf "%c\n",i; print}')"
    local shuffled=$(echo "$str" | sort -R | tr "\n" "\n")
    local chars=${(@f)shuffled}
    local alphabet=${(j::)${(@f)shuffled}}

    if [[ ${#alphabet} != 191 ]]; then
        echoerr "Internal error: invalid alphabet length (${#alphabet})"
        echodata "$alphabet"
        return 1
    fi

    echo "$alphabet"
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

    export __ADF_OBF_INPUT_ALPHABET=$(command cat "$ADF_OBF_INPUT_ALPHABET_FILE")
    export __ADF_OBF_OUTPUT_ALPHABET=$(command cat "$ADF_OBF_OUTPUT_ALPHABET_FILE")

    echosuccess "Done."
}

# Display the current input alphabet
function adf_obf_current_input_alphabet() {
    echo "$__ADF_OBF_INPUT_ALPHABET"
}

# Display the current output alphabet
function adf_obf_current_output_alphabet() {
    echo "$__ADF_OBF_OUTPUT_ALPHABET"
}

# Hash a message to check its integrity during decoding
# or to check if it has been decoded correctly
function adf_obf_checksum() {
    echo -n "$1" | cksum | cut -d\  -f 1 | xargs printf '%0X'
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
    local message=${match[2]}
    
    local msg_checksum=$(adf_obf_checksum "$message")

    if [[ $got_checksum != $msg_checksum ]]; then
        echoerr "Invalid checksum found: expected \z[yellow]°$msg_checksum\z[]°, found \z[yellow]°$got_checksum\z[]° in message: \z[cyan]°$1\z[]°"
        return 3
    fi

    echo "$message"
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

    if [[ ${#2} != 191 ]]; then
        echoerr "Input alphabet is not 191 characters long."
        return 2
    fi

    if [[ ${#3} != 191 ]]; then
        echoerr "Output alphabet is not 191 characters long."
        return 2
    fi

    if [[ $4 == 0 ]]; then
        local is_encoding=1
        local base_alphabet="$2"
        local converted_alphabet="$3"
        local fail_word="encode"
    else
        local is_encoding=0
        local base_alphabet="$3"
        local converted_alphabet="$2"
        local fail_word="decode"
    fi

    local input=""

    if [[ -z "$1" ]]; then
        echoinfo "Please input your message:"
        read input
    else
        if (( $is_encoding )) && ! (( $OBF_ARG_SAFE )); then
            echowarn "ENSURE TO NOT PROVIDE ANY SENSITIVE DATA AS AN ARGUMENT!"
        fi

        input="$1"
    fi

    if [[ -z $input && ! -z $OBF_NO_CHECKSUM ]]; then
        echoerr "Input cannot be empty as it should contain its own checksum."
        return 1
    fi

    if [[ $is_encoding = 1 && -z $OBF_NO_CHECKSUM ]]; then
        input="$(adf_obf_checksum "$input"):$input"
    fi

    local out=()

    for i in {1..${#input}}; do
        local char=${input[i]}
        local index=${base_alphabet[(ie)$char]}

        if [[ $index == 0 ]]; then
            echoerr "Failed to $fail_word character \z[yellow]°$char\z[]°: unknown character"
            return 2
        fi

        out+=("${converted_alphabet[$index]}")
    done

    local decoded=${(j::)out}

    if [[ $is_encoding = 0 && -z $OBF_NO_CHECKSUM ]]; then
        decoded=$(adf_obf_validate_checksum "$decoded")

        if [[ $? != 0 ]]; then
            return 3
        fi
    fi

    echo $decoded
}

# Obfuscate a string
# Useful for storing mildly-sensitive data in source codes
# The local alphabet is used
function adf_obf_encode() {
    if ! ADF_SILENT=1 adf_obf_init_alphabets; then return 1; fi
    adf_obf_transform "$1" "$__ADF_OBF_INPUT_ALPHABET" "$__ADF_OBF_OUTPUT_ALPHABET" 0
}

# Unobfuscate a string generated by the obfuscation function
# The local alphabet is used
function adf_obf_decode() {
    if ! ADF_SILENT=1 adf_obf_init_alphabets; then return 1; fi
    adf_obf_transform "$1" "$__ADF_OBF_INPUT_ALPHABET" "$__ADF_OBF_OUTPUT_ALPHABET" 1
}

# Obfuscate and then unobfuscate a string, to ensure obfuscation works correctly
# The local alphabet is used
function adf_obf_test() {
    if ! ADF_SILENT=1 adf_obf_init_alphabets; then return 1; fi

    echoinfo "Please write your message here:"
    read input

    echoinfo "Plain   (inp) = \z[yellow]°$input\z[]°"

    echoverb "Encoding the message..."
    local encoded=$(OBF_ARG_SAFE=1 adf_obf_encode "$input")
    if [[ $? != 0 ]]; then return $?; fi

    echoinfo "Encoded (obf) = \z[yellow]°$encoded\z[]°"

    echoverb "Decoding the encoded message..."
    local decoded=$(adf_obf_decode "$encoded")
    if [[ $? != 0 ]]; then return $?; fi

    echoinfo "Decoded (out) = \z[yellow]°$decoded\z[]°"

    echoverb "Comparing..."
    if [[ $input != $decoded ]]; then
        echoerr "Input is not the same as output! Seems like an internal problem."
        return 10
    fi

    echosuccess "Message was successfully encoded and decoded."
}
