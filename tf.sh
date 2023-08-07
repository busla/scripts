#!/bin/bash

set -eoux pipefail

PROJECT_DIR="$(git rev-parse --show-toplevel)"
TF_ROOT="${PROJECT_DIR}/terraform"

function info() {
  local msg
  msg="${1}"
  echo "[INFO]: ${msg}"
}

function tf_action() {
  local action env
  action="${1}"
  # shellcheck disable=SC2124
  env="${@: -1}"  # the last argument is env
  shift 1  # remove first argument (action)
  local extra_args=("${@:1:$#-1}")  # get extra arguments, excluding the last one (env)

  # Build up the args array with the action, extra args, optional backend-config, and var-files
  local args=("${action}")
  if [ "${extra_args[@]}" ]; then
    args+=("${extra_args[@]}")
  fi
  if [ "${action}" == "init" ]; then
    args+=("-backend-config=${TF_ROOT}/backend/${env}.tfbackend")
  fi
  args+=(
    "-var-file=${TF_ROOT}/terraform.tfvars"
    "-var-file=${TF_ROOT}/vars/${env}.tfvars"
  )

  info "Running Terraform ${action} ..."
  terraform -chdir="${TF_ROOT}" "${args[@]}"

  if [ "${action}" == "init" ]; then
    info "Running Terraform validate ..."
    terraform validate
  fi
}

option=$1
case $option in
  init|plan|apply|show) tf_action "${@}";;
  *)
    echo "Invalid option: -${option}."
    ;;
esac
