/* name for buildconfig */
{{- define "build.name" -}}
{{- default "buildAkernel" .Values.kernelFullVersion | trunc 63 | trimSuffix "-" | trimSuffix "." | replace "_" "a"| lower -}}
{{- end -}}
