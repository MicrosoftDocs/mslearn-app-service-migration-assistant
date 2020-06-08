#!/usr/bin/env bash

RESOURCEGROUP=$(az group list --query [].name --output tsv)
USERNAME=mslearnuser
PASSWORD="Aa1#$(openssl rand -hex 5)"
DEPLOYMENTNAME=ExerciseEnvironment

echo "Starting provisioning..."

az deployment group create \
  --name $DEPLOYMENTNAME \
  --resource-group "$RESOURCEGROUP" \
  --template-uri "https://raw.githubusercontent.com/MicrosoftDocs/mslearn-app-service-migration-assistant/master/azuredeploy.json" \
  --parameters username=$USERNAME password=$PASSWORD \
  --no-wait

echo "#!/usr/bin/env bash

POLL=\"az deployment group show \\
  --name $DEPLOYMENTNAME \\
  --resource-group $RESOURCEGROUP \\
  --query properties.provisioningState \\
  --output tsv\"

RESULT=\$(eval \$POLL)
STATUS=\"Waiting for provisioning to complete...\"
until [ \"\$RESULT\" != \"Running\" ]
do
  echo -n \"\$STATUS\"
  sleep 10
  STATUS=\".\"
  RESULT=\$(eval \$POLL)
done

if [ \"\$RESULT\" == \"Succeeded\" ]
then
  echo \"Provisioning complete!\"
  echo -e \"\nVM credentials:\"
  echo \"Username: $USERNAME\"
  echo \"Password: $PASSWORD\"
else
  echo \"Provisioning failed\"
fi
" > finish.sh

chmod +x finish.sh

echo "Provisioning started! Continue to the next unit."
