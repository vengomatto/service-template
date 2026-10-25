#!/usr/bin/env bash
# Renders deploy/service.yaml from deploy/service.template.yaml. Called by the Setup service
# workflow; nobody runs it by hand. Inputs come from the environment:
#   NAME, IMAGE, PORT, SERVICE_PATH, HEALTH, DATABASE
# The checks mirror the platform's values schema, so a mistake fails here with a clear message
# instead of later in Argo CD.
set -euo pipefail

fail() { echo "::error::$1"; exit 1; }

: "${NAME:?}" "${IMAGE:?}" "${PORT:?}" "${SERVICE_PATH:?}" "${HEALTH:?}" "${DATABASE:?}"

[[ "$NAME" =~ ^[a-z]([-a-z0-9]{0,40}[a-z0-9])?$ ]] \
  || fail "name '$NAME' must start with a letter and contain only lowercase letters, digits and dashes (max 42 characters)"
[[ "$IMAGE" =~ ^[a-z0-9./_-]+$ ]] \
  || fail "image '$IMAGE' must be lowercase (registry rule); letters, digits, '.', '/', '_' and '-' only"
[[ "$PORT" =~ ^[0-9]+$ ]] && [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ] \
  || fail "port '$PORT' must be a number between 1 and 65535"
[[ "$SERVICE_PATH" =~ ^/[a-z0-9/_-]*$ ]] \
  || fail "path '$SERVICE_PATH' must start with / and use lowercase letters, digits, '/', '_' and '-'"
[[ "$HEALTH" =~ ^/ ]] \
  || fail "health '$HEALTH' must start with /"
[[ "$DATABASE" == "true" || "$DATABASE" == "false" ]] \
  || fail "database must be true or false"

template="deploy/service.template.yaml"
[ -f "$template" ] || fail "$template is missing"

mkdir -p deploy
sed -e "s|__NAME__|${NAME}|g" \
    -e "s|__IMAGE__|${IMAGE}|g" \
    -e "s|__PORT__|${PORT}|g" \
    -e "s|__PATH__|${SERVICE_PATH}|g" \
    -e "s|__HEALTH__|${HEALTH}|g" \
    -e "s|__DATABASE__|${DATABASE}|g" \
    "$template" > deploy/service.yaml

# The result must be valid YAML with no placeholder left.
yq '.' deploy/service.yaml > /dev/null || fail "the rendered deploy/service.yaml is not valid YAML"
if grep -q '__[A-Z_]*__' deploy/service.yaml; then
  fail "a placeholder was not replaced in deploy/service.yaml"
fi
echo "Rendered deploy/service.yaml for '${NAME}'"
