#!/usr/bin/env bash

# Orgs and numeric suffixes
orgs=("north" "south")
numbers=("1" "2")

for from_org in "${orgs[@]}"; do
  from_ns="${from_org}-org"
  for from_num in "${numbers[@]}"; do
    from_pod="${from_org}-busybox-${from_num}"

    for to_org in "${orgs[@]}"; do
      to_ns="${to_org}-org"
      for to_num in "${numbers[@]}"; do
        # Skip self-check
        if [ "$from_org" == "$to_org" ] && [ "$from_num" == "$to_num" ]; then
          continue
        fi

        to_svc="${to_org}-busybox-${to_num}-svc.${to_ns}.svc.cluster.local"

        # Determine expected outcome
        if [[ "$from_org" == "$to_org" ]]; then
          expected_pass="true"
        else
          expected_pass="false"
        fi

        # Run the nc check from source pod
        if kubectl -n "$from_ns" exec -it "$from_pod" -- nc -zv -w1 "$to_svc" 80 >/dev/null 2>&1; then
          actual_pass="true"
        else
          actual_pass="false"
        fi

        # Status formatting
        expected_str=$([[ "$expected_pass" == "true" ]] && echo "PASS" || echo "FAIL")
        actual_str=$([[ "$actual_pass" == "true" ]] && echo "PASS" || echo "FAIL")

        if [ "$expected_pass" == "$actual_pass" ]; then
          echo -e "\e[32mPASS (expected $expected_str got $actual_str)\e[0m FROM ${from_ns^^}-${from_num} TO ${to_ns^^}-${to_num}"
        else
          echo -e "\e[31mFAIL (expected $expected_str got $actual_str)\e[0m FROM ${from_ns^^}-${from_num} TO ${to_ns^^}-${to_num}"
        fi

      done
    done
  done
done