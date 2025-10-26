{{- define "tasks-service.name" -}}
{{ .Chart.Name }}
{{- end -}}

{{- define "tasks-service.fullname" -}}
{{ printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end -}}