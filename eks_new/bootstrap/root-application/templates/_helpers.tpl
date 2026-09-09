{{- define "root-application.name" -}}
gitops-agent-{{ required "cluster.gitopsAgentId is required" .Values.cluster.gitopsAgentId | lower | replace "_" "-" | trunc 52 | trimSuffix "-" }}
{{- end -}}
