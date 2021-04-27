# helm-chart
# Lint the chart
helm lint helm-chart-sources/*
# Create the Helm chart package
cd all/
helm package ../charts/knife

# Create the Helm chart repository index
helm repo index --url https://jijeesh.github.io/helm-chart/ .

# Push the git repository on GitHub

git add . && git commit -m “Initial commit” && git push origin main

# Configure helm client

helm repo add jijeesh https://jijeesh.github.io/helm-chart/
helm repo update

# Test the Helm chart repository
helm search repo nginx

# Add new charts to an existing repository
helm repo index --url https://jijeesh.github.io/helm-chart/ --merge index.yaml .


