{{/*
Name
*/}}
{{- define "kafka.name" -}}
{{- printf "%s" .Release.Name -}}
{{- end }}

{{/*
Cluster Workload Name
*/}}
{{- define "kafka.clusterName" -}}
{{- printf "%s-%s" (include "kafka.name" .) .Values.kafka.name -}}
{{- end }}

{{/*
Convert .Values.kafka.memory to appropriate JVM heap size settings.
*/}}
{{- define "kafka.heap.opts" -}}
{{- $memory := default "512Mi" .Values.kafka.memory }}
{{- $memoryInMi := 0 }}
{{- if hasSuffix "Gi" $memory }}
  {{- $value := trimSuffix "Gi" $memory | float64 }}
  {{- $memoryInMi = mul $value 1024 | int }}
{{- else if hasSuffix "Mi" $memory }}
  {{- $memoryInMi = trimSuffix "Mi" $memory | int }}
{{- else }}
  {{- $memoryInMi = 512 }} # Default to 512Mi if no suffix
{{- end }}
-Xmx{{ $memoryInMi }}m -Xms{{ $memoryInMi }}m
{{- end }}

{{- define "kafka.validateListenerConfig" -}}
  {{- if not .name -}}
    {{- fail "Error: 'name' must be provided for the listener" -}}
  {{- end -}}
  {{- if not .protocol -}}
    {{- fail "Error: 'protocol' must be provided for the listener" -}}
  {{- end -}}
  {{- if not (or .publicAddress .containerPort) -}}
    {{- fail "Error: At least one of 'publicAddress' or 'containerPort' must be provided for the listener" -}}
  {{- end -}}
  {{- if and .publicAddress .containerPort -}}
    {{- fail "Error: When publicAddress is set for the listener, containerPort should not be specified as it will be automatically set to port range 3000-3004" -}}
  {{- end -}}
  {{- if .containerPort -}}
    {{- $port := .containerPort | printf "%s" }}
    {{- if or (eq $port "9091") (eq $port "9093") (eq $port "9094") -}}
      {{- fail "Error: containerPort cannot be 9091, 9093, or 9094 for listener" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "kafka.validateAdminExists" -}}
{{- $adminFound := false -}}
{{- $saslPlaintextExists := false -}}
{{- range .Values.kafka.listeners -}}
  {{- if eq .protocol "SASL_PLAINTEXT" -}}
    {{- $saslPlaintextExists = true -}}
    {{- if and .sasl .sasl.admin -}}
      {{- $adminFound = true -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if and $saslPlaintextExists (not $adminFound) -}}
  {{- fail "Error: At least one SASL_PLAINTEXT listener must have an admin user configured in sasl.admin" -}}
{{- end -}}
{{- end -}}

{{- define "kafka.validateAuthConfig" -}}
{{- if eq .protocol "SASL_PLAINTEXT" -}}
  {{- if not .sasl -}}
    {{- fail (printf "Error: SASL_PLAINTEXT protocol requires sasl configuration to be enabled for listener '%s'" .name) -}}
  {{- else if not .sasl.users -}}
    {{- fail (printf "Error: SASL_PLAINTEXT protocol requires at least one user to be defined in sasl.users for listener '%s'" .name) -}}
  {{- else -}}
    {{- $userCount := len (splitList "," .sasl.users) -}}
    {{- if not .sasl.passwords -}}
      {{- fail (printf "Error: sasl.passwords must be provided when sasl.users is defined for listener '%s'" .name) -}}
    {{- else -}}
      {{- $passwordCount := len (splitList "," .sasl.passwords) -}}
      {{- if ne $userCount $passwordCount -}}
        {{- fail (printf "Error: Number of users (%d) does not match number of passwords (%d) for listener '%s'" $userCount $passwordCount .name) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "kafka.validateReplicas" -}}
{{- $replicas := .Values.kafka.replicas | int }}
{{- if or (gt $replicas 5) (eq $replicas 2) -}}
  {{- fail "Invalid value for kafka.replicas. It must be less than or equal to 5 and not equal to 2." -}}
{{- end -}}
{{- end -}}

{{- define "kafka.validateOnePublicAddress" -}}
{{- $publicAddressCount := 0 -}}
{{- range .Values.kafka.listeners }}
  {{- if .publicAddress }}
    {{- $publicAddressCount = add $publicAddressCount 1 -}}
  {{- end }}
{{- end }}
{{- if gt $publicAddressCount 1 -}}
  {{- fail "There must be at most one listener with a publicAddress set." -}}
{{- end }}
{{- end -}}

{{- define "kafka.clientBootstrapAddress" -}}
{{- $clusterName := include "kafka.clusterName" . -}}
{{- $bootstrapAddress := "" -}}
{{- $listenerName := "" -}}

{{- if .listenerName -}}
  {{- $listenerName = .listenerName -}}
{{- else if .Values.kafka_connectors -}}
  {{- range .Values.kafka_connectors -}}
    {{- if .listener -}}
      {{- $listenerName = .listener -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- if $listenerName -}}
  {{- if hasKey .Values.kafka.listeners $listenerName -}}
    {{- $listener := index .Values.kafka.listeners $listenerName -}}
    {{- if $listener.publicAddress -}}
      {{- $bootstrapAddress = printf "%s:3000" $listener.publicAddress -}}
    {{- else -}}
      {{- $containerPort := $listener.containerPort | int -}}
      {{- $bootstrapAddress = printf "%s:%d" $clusterName $containerPort -}}
    {{- end -}}
  {{- else -}}
    {{- $bootstrapAddress = include "kafka.bootstrapAddress" . -}}
  {{- end -}}
{{- else -}}
  {{- $bootstrapAddress = include "kafka.bootstrapAddress" . -}}
{{- end -}}

{{- $bootstrapAddress -}}
{{- end -}}

{{- define "kafka.propertiesMapToList" -}}
{{- range $key, $value := . -}}
{{ $key }}={{ $value }}
{{- end -}}
{{- end -}}



{{- define "kafka.connectors.script" -}}
#!/bin/bash
set -ex

# Function to download and extract artifacts
download_and_extract() {
  local artifact_type=$1
  local artifact_url=$2
  local plugin_path=$3
  local temp_dir=$(mktemp -d)
  
  echo "Downloading artifact from $artifact_url"
  
  if [ "$artifact_type" == "jar" ]; then
    # For jar files, download directly to plugin path
    curl -sSL "$artifact_url" -o "$plugin_path/$(basename "$artifact_url")"
    echo "Downloaded JAR file to $plugin_path/$(basename "$artifact_url")"
  else
    # For archives, download to temp dir and extract
    local archive_file="$temp_dir/$(basename "$artifact_url")"
    curl -sSL "$artifact_url" -o "$archive_file"
    
    echo "Extracting $artifact_type archive to $plugin_path"
    case "$artifact_type" in
      "tgz"|"tar.gz")
        tar -xzf "$archive_file" -C "$plugin_path"
        ;;
      "tar")
        tar -xf "$archive_file" -C "$plugin_path"
        ;;
      "zip")
        unzip -o "$archive_file" -d "$plugin_path"
        ;;
      *)
        echo "Unsupported archive type: $artifact_type"
        ;;
    esac
    
    rm -rf "$temp_dir"
  fi
}

# Function to create or update a connector
create_or_update_connector() {
  local connector_name=$1
  local config=$2
  
  echo "Checking if connector $connector_name exists..."

  # Try to delete the connector if it exists
  curl -s -X DELETE "http://localhost:8083/connectors/$connector_name" || true
  
  echo "Creating connector $connector_name with config:"
  echo "$config"
  
  # Create the connector
  curl -s -X POST -H "Content-Type: application/json" --data "$config" http://localhost:8083/connectors
  
  echo "Connector $connector_name created/updated successfully"
}

# Process each Kafka connector
echo "Setting up Kafka connector"

# Download and extract artifacts for each plugin
{{- range .plugins }}
echo "Processing plugin: {{ .name }}"
{{- range .artifacts }}
download_and_extract "{{ .type }}" "{{ .url }}" "{{ $.plugins_folder }}"
{{- end }}
{{- end }}

# Start Kafka Connect in the background
echo "Starting Kafka Connect distributed worker..."

# Start Kafka Connect in the background
nohup /opt/bitnami/kafka/bin/connect-distributed.sh /opt/bitnami/kafka/config/connect-distributed.properties > /proc/1/fd/1 2>&1 &

# Wait for Kafka Connect to start
echo "Waiting for Kafka Connect to start..."
until curl -s http://localhost:8083/ > /dev/null; do
  echo "Waiting for Kafka Connect REST API..."
  sleep 5
done

echo "Kafka Connect started. Waiting 10 seconds..."
sleep 10

# Create/update connectors
{{- range .plugins }}
echo "Creating/updating connector: {{ .name }}"
CONFIG=$(cat << 'EOF'
{
  "name": "{{ .name }}",
  "config": {
    {{- $first := true }}
    {{- range $key, $value := .config }}
    {{- if $first }}{{ $first = false }}{{ else }},{{ end }}
    "{{ $key }}": "{{ $value }}"
    {{- end }}
  }
}
EOF
)

create_or_update_connector "{{ .name }}" "$CONFIG"
{{- end }}

echo "All Kafka connectors have been configured and started."
sleep infinity
{{- end }}