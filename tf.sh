#!/usr/bin/env bash

# See: https://aws-blog.de/2019/05/managing-multiple-stages-with-terraform.html

# How to: . switch_environment.sh ENVIRONMENT_NAME

STAGE=$1
SUBC=$2
PARAMS=${@:3}

VARS_FILE=environments/${STAGE}/variables.local.json
BACKEND_FILE=environments/${STAGE}/backend.config

if [[ ! -d "environments/${STAGE}" ]]; then
    echo "The environment '${STAGE}' doesn't exist under environments/ - please check the spelling!"
    echo "These environments are available:"
    ls environments/
    return 1
fi

if [[ -f "${BACKEND_FILE}" ]]; then
    # Configure the Backend
    echo "Running: terraform init -backend-config=environments/${STAGE}/backend.config ."
    terraform init -backend-config=environments/${STAGE}/backend.config .
else
    echo "The backend configuration is missing at environments/${STAGE}/backend.config!"
    return 2
fi

if [[ -f "${VARS_FILE}" ]]; then
    
    # List of commands that can accept the -var-file argument
    sub_commands_with_vars=(destroy plan)

    # List of commands that accept the backend argument
    sub_commands_with_backend=(init)

    # ${@:2} means that we append all of the arguments after tf init

    if [[ " ${sub_commands_with_vars[@]} " =~ " $SUBC " ]]; then
        # Only some of the subcommands can work with the -var-file argument
        echo "Running: terraform $SUBC ${PARAMS} -var-file=${VARS_FILE}"
        terraform $SUBC ${PARAMS} -var-file=${VARS_FILE}
    elif [[ " ${sub_commands_with_backend[@]} " =~ " $SUBC " ]]; then
        # Only some sub commands require the backend configuration
        echo "Running: terraform init -backend-config=${BACKEND_FILE} ${@:2}"
        terraform init -backend-config=${BACKEND_FILE} ${@:2}
    else
        echo "Running: terraform $@"
        terraform $@
    fi

else
    echo "Couldn't find the variables file here: ${VARS_FILE}"
    return 3
fi