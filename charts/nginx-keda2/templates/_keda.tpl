
{{/*
Return the appropriate keda version for deployment.
*/}}
{{- define "keda.version" -}}
{{- if .Capabilities.APIVersions.Has "keda.sh/v1alpha1" -}}
{{- print "keda.sh/v1alpha1" -}}
{{- else if .Capabilities.APIVersions.Has "keda.k8s.io/v1alpha1" -}}
{{- print "keda.k8s.io/v1alpha1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate keda targ for deployment.
*/}}
{{- define "keda.scaletargetrefname" -}}
{{- if .Capabilities.APIVersions.Has "keda.sh/v1alpha1" -}}
{{- print "name" -}}
{{- else if .Capabilities.APIVersions.Has "keda.k8s.io/v1alpha1" -}}
{{- print "deploymentName" -}}
{{- end -}}
{{- end -}}