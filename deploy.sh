# env should be a subdir under environments/
ENV=$1
# action should be init, plan, or apply
ACT=$2

VARS_FILE=environments/${ENV}/variables.local.json
BACKEND_FILE=environments/${ENV}/backend.config

# validate the environment
if [[ ! -d "environments/${ENV}" ]]; then
    echo "The environment '${ENV}' doesn't exist under environments/ - please check the spelling!"
    echo "These environments are available:"
    ls environments/
    exit
fi

# validate action
expected_acts=(init plan apply destroy deploy delete)

if [[ " ${expected_acts[@]} " =~ " $ACT " ]]; then
    echo "Running ${ACT}..."
else
    echo "Invalid action: ${ACT}"
    exit
fi

if [[ -f "${BACKEND_FILE}" ]]; then
    touch ${BACKEND_FILE}
fi

# get variables
VARS_FILE="environments/${ENV}/variables.local.json"
SP=($( jq -r '.appId' ${VARS_FILE} ))
PASS=($( jq -r '.password' ${VARS_FILE} ))
TENANT=($( jq -r '.tenant' ${VARS_FILE} ))
    
# authenticate with the service principal
az logout
az login --service-principal --username ${SP} --password ${PASS} --tenant ${TENANT}

if [[ " ${ACT} " =~ " init " ]]; then
    terraform init -backend-config=${BACKEND_FILE} .
    
elif [[ " ${ACT} " =~ " plan " ]]; then
    terraform plan -var-file=${VARS_FILE} --out main.tfplan
    
elif [[ " ${ACT} " =~ " apply " ]]; then
    terraform apply main.tfplan 
    az role assignment create --assignee ${SP} --role Contributor --resource-group rg-playground-${ENV}
    
elif [[ " ${ACT} " =~ " destroy " ]]; then
    terraform destroy
    
elif [[ " ${ACT} " =~ " deploy " ]]; then
    
    # install k8s CLI
    az aks install-cli

    # get aks credentials
    az aks get-credentials --resource-group rg-playground-${ENV} --name aks-rvaj82-playground-${ENV}

    # deploy azure containers
    kubectl apply -f deploy.yaml      
    
elif [[ " ${ACT} " =~ " delete " ]]; then
    
    # delete k8s resoruce
    az aks delete --name aks-rvaj82-playground-${ENV} --resource-group rg-playground-${ENV} --yes

fi;

# always logout so as to not impact any other terminal sessions
az logout