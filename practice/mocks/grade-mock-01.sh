#!/usr/bin/env bash
# grade-mock-01.sh — Auto-grader for CKA Mock Exam 01
# Usage: bash practice/mocks/grade-mock-01.sh
#
# set -uo pipefail: unbound vars are errors; pipeline failures propagate.
# Intentionally NOT -e so a failed assertion does not abort grading.
set -uo pipefail

TOTAL=0
PASS_THRESHOLD=66

GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

pass() {
  local task=$1 weight=$2 label=$3
  echo -e "${GREEN}PASS${RESET}  Task ${task} (${weight}%): ${label}"
  TOTAL=$((TOTAL + weight))
}

fail() {
  local task=$1 weight=$2 label=$3 reason=$4
  echo -e "${RED}FAIL${RESET}  Task ${task} (${weight}%): ${label}"
  echo "       Reason: ${reason}"
}

echo ""
echo "============================================"
echo " CKA Mock Exam 01 — Auto-Grader"
echo "============================================"
echo ""

# ---------------------------------------------------------------------------
# Task 1 (12%) — Deployment web in mock01-web
# ---------------------------------------------------------------------------
T1_WEIGHT=12
T1_LABEL="Deployment web / nginx:1.27 / 3 replicas / resource requests+limits"

t1_ok=true
t1_reason=""

# Deployment exists
if ! kubectl get deployment web -n mock01-web &>/dev/null; then
  t1_ok=false
  t1_reason="Deployment 'web' not found in namespace mock01-web"
fi

if [[ "${t1_ok}" == "true" ]]; then
  replicas=$(kubectl get deployment web -n mock01-web -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
  if [[ "${replicas}" != "3" ]]; then
    t1_ok=false
    t1_reason="spec.replicas is '${replicas}', expected 3"
  fi
fi

if [[ "${t1_ok}" == "true" ]]; then
  image=$(kubectl get deployment web -n mock01-web \
    -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
  if [[ "${image}" != "nginx:1.27" ]]; then
    t1_ok=false
    t1_reason="container image is '${image}', expected nginx:1.27"
  fi
fi

if [[ "${t1_ok}" == "true" ]]; then
  cpu_req=$(kubectl get deployment web -n mock01-web \
    -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null || true)
  if [[ "${cpu_req}" != "100m" ]]; then
    t1_ok=false
    t1_reason="cpu request is '${cpu_req}', expected 100m"
  fi
fi

if [[ "${t1_ok}" == "true" ]]; then
  mem_req=$(kubectl get deployment web -n mock01-web \
    -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null || true)
  if [[ "${mem_req}" != "64Mi" ]]; then
    t1_ok=false
    t1_reason="memory request is '${mem_req}', expected 64Mi"
  fi
fi

if [[ "${t1_ok}" == "true" ]]; then
  mem_lim=$(kubectl get deployment web -n mock01-web \
    -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)
  if [[ "${mem_lim}" != "128Mi" ]]; then
    t1_ok=false
    t1_reason="memory limit is '${mem_lim}', expected 128Mi"
  fi
fi

if [[ "${t1_ok}" == "true" ]]; then
  ready=$(kubectl get deployment web -n mock01-web \
    -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
  if [[ "${ready}" != "3" ]]; then
    t1_ok=false
    t1_reason="readyReplicas is '${ready}', expected 3. If pods are still starting, wait and re-run the grader."
  fi
fi

if [[ "${t1_ok}" == "true" ]]; then
  pass 1 ${T1_WEIGHT} "${T1_LABEL}"
else
  fail 1 ${T1_WEIGHT} "${T1_LABEL}" "${t1_reason}"
fi

# ---------------------------------------------------------------------------
# Task 2 (15%) — RBAC in mock01-rbac
# ---------------------------------------------------------------------------
T2_WEIGHT=15
T2_LABEL="ServiceAccount app-sa / Role pod-reader / RoleBinding app-sa-binding"

t2_ok=true
t2_reason=""

SA="system:serviceaccount:mock01-rbac:app-sa"

# ServiceAccount exists
if ! kubectl get serviceaccount app-sa -n mock01-rbac &>/dev/null; then
  t2_ok=false
  t2_reason="ServiceAccount 'app-sa' not found in namespace mock01-rbac"
fi

if [[ "${t2_ok}" == "true" ]]; then
  can_get=$(kubectl auth can-i get pods \
    --as="${SA}" -n mock01-rbac 2>/dev/null || echo "no")
  if [[ "${can_get}" != "yes" ]]; then
    t2_ok=false
    t2_reason="app-sa cannot 'get pods' in mock01-rbac (auth can-i returned: ${can_get})"
  fi
fi

if [[ "${t2_ok}" == "true" ]]; then
  can_list=$(kubectl auth can-i list pods \
    --as="${SA}" -n mock01-rbac 2>/dev/null || echo "no")
  if [[ "${can_list}" != "yes" ]]; then
    t2_ok=false
    t2_reason="app-sa cannot 'list pods' in mock01-rbac (auth can-i returned: ${can_list})"
  fi
fi

if [[ "${t2_ok}" == "true" ]]; then
  can_delete=$(kubectl auth can-i delete pods \
    --as="${SA}" -n mock01-rbac 2>/dev/null || echo "no")
  if [[ "${can_delete}" != "no" ]]; then
    t2_ok=false
    t2_reason="app-sa CAN 'delete pods' — Role grants too many permissions"
  fi
fi

if [[ "${t2_ok}" == "true" ]]; then
  pass 2 ${T2_WEIGHT} "${T2_LABEL}"
else
  fail 2 ${T2_WEIGHT} "${T2_LABEL}" "${t2_reason}"
fi

# ---------------------------------------------------------------------------
# Task 3 (18%) — NetworkPolicy web-allow-frontend in mock01-web
# ---------------------------------------------------------------------------
T3_WEIGHT=18
T3_LABEL="NetworkPolicy web-allow-frontend / podSelector app=web / allow TCP 80 from role=frontend"

t3_ok=true
t3_reason=""

if ! kubectl get networkpolicy web-allow-frontend -n mock01-web &>/dev/null; then
  t3_ok=false
  t3_reason="NetworkPolicy 'web-allow-frontend' not found in namespace mock01-web"
fi

if [[ "${t3_ok}" == "true" ]]; then
  pod_sel=$(kubectl get networkpolicy web-allow-frontend -n mock01-web \
    -o jsonpath='{.spec.podSelector.matchLabels.app}' 2>/dev/null || true)
  if [[ "${pod_sel}" != "web" ]]; then
    t3_ok=false
    t3_reason="spec.podSelector.matchLabels.app is '${pod_sel}', expected 'web'"
  fi
fi

if [[ "${t3_ok}" == "true" ]]; then
  policy_types=$(kubectl get networkpolicy web-allow-frontend -n mock01-web \
    -o jsonpath='{.spec.policyTypes}' 2>/dev/null || true)
  if [[ "${policy_types}" != *"Ingress"* ]]; then
    t3_ok=false
    t3_reason="spec.policyTypes does not contain 'Ingress' (got: ${policy_types})"
  fi
fi

if [[ "${t3_ok}" == "true" ]]; then
  from_sel=$(kubectl get networkpolicy web-allow-frontend -n mock01-web \
    -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels.role}' 2>/dev/null || true)
  if [[ "${from_sel}" != "frontend" ]]; then
    t3_ok=false
    t3_reason="ingress[0].from[0].podSelector.matchLabels.role is '${from_sel}', expected 'frontend'"
  fi
fi

if [[ "${t3_ok}" == "true" ]]; then
  port=$(kubectl get networkpolicy web-allow-frontend -n mock01-web \
    -o jsonpath='{.spec.ingress[0].ports[0].port}' 2>/dev/null || true)
  proto=$(kubectl get networkpolicy web-allow-frontend -n mock01-web \
    -o jsonpath='{.spec.ingress[0].ports[0].protocol}' 2>/dev/null || true)
  if [[ "${port}" != "80" ]]; then
    t3_ok=false
    t3_reason="ingress port is '${port}', expected 80"
  elif [[ "${proto}" != "TCP" ]]; then
    t3_ok=false
    t3_reason="ingress protocol is '${proto}', expected TCP"
  fi
fi

if [[ "${t3_ok}" == "true" ]]; then
  pass 3 ${T3_WEIGHT} "${T3_LABEL}"
else
  fail 3 ${T3_WEIGHT} "${T3_LABEL}" "${t3_reason}"
fi

# ---------------------------------------------------------------------------
# Task 4 (15%) — PV mock01-pv + PVC data-pvc in mock01-data
# ---------------------------------------------------------------------------
T4_WEIGHT=15
T4_LABEL="PV mock01-pv (hostPath /mnt/mock01, 1Gi, RWO, manual) + PVC data-pvc Bound"

t4_ok=true
t4_reason=""

if ! kubectl get persistentvolume mock01-pv &>/dev/null; then
  t4_ok=false
  t4_reason="PersistentVolume 'mock01-pv' not found"
fi

if [[ "${t4_ok}" == "true" ]]; then
  if ! kubectl get pvc data-pvc -n mock01-data &>/dev/null; then
    t4_ok=false
    t4_reason="PersistentVolumeClaim 'data-pvc' not found in namespace mock01-data"
  fi
fi

if [[ "${t4_ok}" == "true" ]]; then
  pvc_phase=$(kubectl get pvc data-pvc -n mock01-data \
    -o jsonpath='{.status.phase}' 2>/dev/null || true)
  if [[ "${pvc_phase}" != "Bound" ]]; then
    t4_ok=false
    t4_reason="PVC data-pvc status.phase is '${pvc_phase}', expected Bound"
  fi
fi

if [[ "${t4_ok}" == "true" ]]; then
  pvc_vol=$(kubectl get pvc data-pvc -n mock01-data \
    -o jsonpath='{.spec.volumeName}' 2>/dev/null || true)
  if [[ "${pvc_vol}" != "mock01-pv" ]]; then
    t4_ok=false
    t4_reason="PVC spec.volumeName is '${pvc_vol}', expected mock01-pv"
  fi
fi

if [[ "${t4_ok}" == "true" ]]; then
  pass 4 ${T4_WEIGHT} "${T4_LABEL}"
else
  fail 4 ${T4_WEIGHT} "${T4_LABEL}" "${t4_reason}"
fi

# ---------------------------------------------------------------------------
# Task 5 (20%) — PriorityClass mock01-high + Pod important
# ---------------------------------------------------------------------------
T5_WEIGHT=20
T5_LABEL="PriorityClass mock01-high (value=100000, not global default) + Pod important"

t5_ok=true
t5_reason=""

if ! kubectl get priorityclass mock01-high &>/dev/null; then
  t5_ok=false
  t5_reason="PriorityClass 'mock01-high' not found"
fi

if [[ "${t5_ok}" == "true" ]]; then
  pc_value=$(kubectl get priorityclass mock01-high \
    -o jsonpath='{.value}' 2>/dev/null || true)
  if [[ "${pc_value}" != "100000" ]]; then
    t5_ok=false
    t5_reason="PriorityClass value is '${pc_value}', expected 100000"
  fi
fi

if [[ "${t5_ok}" == "true" ]]; then
  pc_global=$(kubectl get priorityclass mock01-high \
    -o jsonpath='{.globalDefault}' 2>/dev/null || true)
  if [[ "${pc_global}" == "true" ]]; then
    t5_ok=false
    t5_reason="PriorityClass globalDefault is true — must not be the global default"
  fi
fi

if [[ "${t5_ok}" == "true" ]]; then
  if ! kubectl get pod important -n mock01-web &>/dev/null; then
    t5_ok=false
    t5_reason="Pod 'important' not found in namespace mock01-web"
  fi
fi

if [[ "${t5_ok}" == "true" ]]; then
  pod_pc=$(kubectl get pod important -n mock01-web \
    -o jsonpath='{.spec.priorityClassName}' 2>/dev/null || true)
  if [[ "${pod_pc}" != "mock01-high" ]]; then
    t5_ok=false
    t5_reason="pod spec.priorityClassName is '${pod_pc}', expected mock01-high"
  fi
fi

if [[ "${t5_ok}" == "true" ]]; then
  pod_prio=$(kubectl get pod important -n mock01-web \
    -o jsonpath='{.spec.priority}' 2>/dev/null || true)
  if [[ "${pod_prio}" != "100000" ]]; then
    t5_ok=false
    t5_reason="pod spec.priority is '${pod_prio}', expected 100000"
  fi
fi

if [[ "${t5_ok}" == "true" ]]; then
  pass 5 ${T5_WEIGHT} "${T5_LABEL}"
else
  fail 5 ${T5_WEIGHT} "${T5_LABEL}" "${t5_reason}"
fi

# ---------------------------------------------------------------------------
# Task 6 (20%) — HPA web in mock01-web
# ---------------------------------------------------------------------------
T6_WEIGHT=20
T6_LABEL="HPA web / min=2 max=5 / CPU target 50% / scaleTargetRef=web Deployment"

t6_ok=true
t6_reason=""

if ! kubectl get hpa web -n mock01-web &>/dev/null; then
  t6_ok=false
  t6_reason="HPA 'web' not found in namespace mock01-web"
fi

if [[ "${t6_ok}" == "true" ]]; then
  hpa_min=$(kubectl get hpa web -n mock01-web \
    -o jsonpath='{.spec.minReplicas}' 2>/dev/null || true)
  if [[ "${hpa_min}" != "2" ]]; then
    t6_ok=false
    t6_reason="HPA spec.minReplicas is '${hpa_min}', expected 2"
  fi
fi

if [[ "${t6_ok}" == "true" ]]; then
  hpa_max=$(kubectl get hpa web -n mock01-web \
    -o jsonpath='{.spec.maxReplicas}' 2>/dev/null || true)
  if [[ "${hpa_max}" != "5" ]]; then
    t6_ok=false
    t6_reason="HPA spec.maxReplicas is '${hpa_max}', expected 5"
  fi
fi

if [[ "${t6_ok}" == "true" ]]; then
  hpa_target=$(kubectl get hpa web -n mock01-web \
    -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}' 2>/dev/null || true)
  if [[ "${hpa_target}" != "50" ]]; then
    t6_ok=false
    t6_reason="HPA CPU averageUtilization target is '${hpa_target}', expected 50"
  fi
fi

if [[ "${t6_ok}" == "true" ]]; then
  hpa_ref=$(kubectl get hpa web -n mock01-web \
    -o jsonpath='{.spec.scaleTargetRef.name}' 2>/dev/null || true)
  if [[ "${hpa_ref}" != "web" ]]; then
    t6_ok=false
    t6_reason="HPA scaleTargetRef.name is '${hpa_ref}', expected web"
  fi
fi

if [[ "${t6_ok}" == "true" ]]; then
  pass 6 ${T6_WEIGHT} "${T6_LABEL}"
else
  fail 6 ${T6_WEIGHT} "${T6_LABEL}" "${t6_reason}"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo -e " ${BOLD}Total Score: ${TOTAL} / 100${RESET}"
echo "============================================"
if [[ "${TOTAL}" -ge "${PASS_THRESHOLD}" ]]; then
  echo -e " ${GREEN}${BOLD}PASS (>= ${PASS_THRESHOLD})${RESET}"
else
  echo -e " ${RED}${BOLD}FAIL (< ${PASS_THRESHOLD})${RESET}"
fi
echo ""
