###################################################################################
####### THIS CHART IS A COPY OF ELASTICSEARCH (DO NOT MODIFY)               #######
####### DUE TO A BUG IN HELM PUBLISH WHEN USING ALIAS AND MULTIPLE VERSIONS #######
####### SEE: https://github.com/helm/helm/issues/3909                       #######
###################################################################################

rm -rf ./templates
cp -r ../elasticsearch/ .
sed -i '' -e "s|^name: elasticsearch|name: elasticsearch6|" Chart.yaml
