{{/*
Kubernetes standard labels
{{ include "libs.labels.standard" (dict "customLabels" .Values.commonLabels "context" $) -}}
*/}}
{{- define "libs.labels.standard" -}}
{{- if and (hasKey . "customLabels") (hasKey . "context") -}}
{{- $default := dict "app.kubernetes.io/component" (include "libs.names.name" .context) "app.kubernetes.io/chart" (include "libs.names.chart" .context) "app.kubernetes.io/managed-by" .context.Release.Service -}}
{{- with .context.Chart.AppVersion -}}
{{- $_ := set $default "app.kubernetes.io/version" . -}}
{{- end -}}
{{ template "libs.tplvalues.merge" (dict "values" (list .customLabels $default) "context" .context) }}
{{- else -}}
app.kubernetes.io/component: {{ include "libs.names.name" . }}
app.kubernetes.io/chart: {{ include "libs.names.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . | quote }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Labels used on immutable fields such as deploy.spec.selector.matchLabels or svc.spec.selector
{{ include "libs.labels.matchLabels" (dict "customLabels" .Values.podLabels "context" $) -}}

We don't want to loop over custom labels appending them to the selector
since it's very likely that it will break deployments, services, etc.
However, it's important to overwrite the standard labels if the user
overwrote them on metadata.labels fields.
*/}}
{{- define "libs.labels.matchLabels" -}}
{{- if and (hasKey . "customLabels") (hasKey . "context") -}}
{{ merge (pick (include "libs.tplvalues.render" (dict "value" .customLabels "context" .context) | fromYaml) "app.kubernetes.io/name") (dict "app.kubernetes.io/component" (include "libs.names.name" .context)) | toYaml }}
{{- else -}}
app.kubernetes.io/component: {{ include "libs.names.name" . }}
{{- end -}}
{{- end -}}

