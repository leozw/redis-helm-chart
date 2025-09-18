{{/*
Expand the name of the chart.
*/}}
{{- define "redis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "redis.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "redis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "redis.labels" -}}
helm.sh/chart: {{ include "redis.chart" . }}
{{ include "redis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "redis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "redis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account
*/}}
{{- define "redis.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "redis.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the password secret name
*/}}
{{- define "redis.secretName" -}}
{{- if .Values.auth.existingSecret }}
    {{- printf "%s" .Values.auth.existingSecret }}
{{- else }}
    {{- printf "%s-secret" (include "redis.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get the password key
*/}}
{{- define "redis.secretPasswordKey" -}}
{{- if .Values.auth.existingSecret }}
    {{- printf "%s" .Values.auth.existingSecretPasswordKey }}
{{- else }}
    {{- printf "redis-password" }}
{{- end }}
{{- end }}

{{/*
Return Redis password
*/}}
{{- define "redis.password" -}}
{{- if .Values.auth.enabled }}
    {{- .Values.auth.password }}
{{- else }}
    {{- printf "" }}
{{- end }}
{{- end }}

{{/*
Return Redis configuration configmap name
*/}}
{{- define "redis.configmapName" -}}
{{- printf "%s-config" (include "redis.fullname" .) }}
{{- end }}

{{/*
Return true if persistence is enabled
*/}}
{{- define "redis.persistence.enabled" -}}
{{- if .Values.persistence.enabled }}
    {{- true }}
{{- else }}
    {{- false }}
{{- end }}
{{- end }}

{{/*
Get Redis port
*/}}
{{- define "redis.port" -}}
{{- .Values.redis.port | default 6379 }}
{{- end }}

{{/*
Create the Redis command
*/}}
{{- define "redis.command" -}}
- redis-server
- /etc/redis/redis.conf
{{- if .Values.auth.enabled }}
- --requirepass
- $(REDIS_PASSWORD)
{{- end }}
{{- end }}

{{/*
Service name
*/}}
{{- define "redis.serviceName" -}}
{{- printf "%s" (include "redis.fullname" .) }}
{{- end }}

{{/*
Master service name
*/}}
{{- define "redis.masterServiceName" -}}
{{- printf "%s-master" (include "redis.fullname" .) }}
{{- end }}

{{/*
Replica service name
*/}}
{{- define "redis.replicaServiceName" -}}
{{- printf "%s-replica" (include "redis.fullname" .) }}
{{- end }}

{{/*
Is master
*/}}
{{- define "redis.isMaster" -}}
{{- if eq .Values.architecture "replication" }}
    {{- if .isMaster }}
        {{- true }}
    {{- else }}
        {{- false }}
    {{- end }}
{{- else }}
    {{- true }}
{{- end }}
{{- end }}