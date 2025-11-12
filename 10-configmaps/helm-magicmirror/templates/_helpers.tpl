{{- define "mm.labels" -}}
app.kubernetes.io/name: magicmirror-server
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
