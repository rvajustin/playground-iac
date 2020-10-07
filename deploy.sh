# $ENV should be dev or prd
ENV=$1
# $ACTION should be init, plan, or apply
ACT=$2

expected_envs=(dev prd)
expected_acts=(init plan apply destroy deploy)

if [[ " ${expected_envs[@]} " =~ " $ENV " ]]; then
    echo "Running action for ${ENV}..."
else
    echo "Invalid environment: ${ENV}"
    exit
fi

if [[ " ${expected_acts[@]} " =~ " $ACT " ]]; then
    echo "Running ${ACT}..."
else
    echo "Invalid action: ${ACT}"
    exit
fi

if [[ " ${ACT} " =~ " init " ]]; then
    sh tf.sh ${ENV} init
    
elif [[ " ${ACT} " =~ " plan " ]]; then
    sh tf.sh ${ENV} plan --out main.tfplan
    
elif [[ " ${ACT} " =~ " apply " ]]; then
    terraform apply main.tfplan 
    
elif [[ " ${ACT} " =~ " destroy " ]]; then
    sh tf.sh ${ENV} destroy ${@:2}
    
elif [[ " ${ACT} " =~ " deploy " ]]; then
    
    # get variables
    VARS_FILE="environments/${ENV}/variables.local.json"
    SP=($( jq -r '.appId' ${VARS_FILE} ))
    PASS=($( jq -r '.password' ${VARS_FILE} ))
    TENANT=($( jq -r '.tenant' ${VARS_FILE} ))
    
    # install k8s CLI
    az aks install-cli
    
    # authenticate with the service principal
    az login --service-principal --username ${SP} --password ${PASS} --tenant ${TENANT}

    # get aks credentials
    az aks get-credentials --resource-group rg-playground-${ENV} --name aks-rvaj82-playground-${ENV}

    # deploy azure containers
    kubectl apply -f deploy.yaml       

fi;