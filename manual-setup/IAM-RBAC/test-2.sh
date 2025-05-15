#!/usr/bin/env bash

# Namespaces and numeric suffixes
namespaces=("north-org" "south-org")
numbers=("1" "2")

for from_ns in "${namespaces[@]}"; do
  for from_num in "${numbers[@]}"; do
    # Build source pod name
    from_prefix="$(echo "$from_ns" | sed 's/-org//')"
    from_pod="${from_prefix}-busybox-${from_num}"

    # (Optional) Skip if the pod doesn't exist
    # if ! kubectl -n "$from_ns" get pod "$from_pod" &>/dev/null; then
    #   continue
    # fi

    for to_ns in "${namespaces[@]}"; do
      for to_num in "${numbers[@]}"; do
        # Skip self-check (same namespace + same number)
        if [ "$from_ns" == "$to_ns" ] && [ "$from_num" == "$to_num" ]; then
          continue
        fi

        # Build destination service name
        to_prefix="$(echo "$to_ns" | sed 's/-org//')"
        to_svc="${to_prefix}-busybox-${to_num}-svc.${to_ns}.svc.cluster.local"

        # Decide the expected connectivity outcome
        #   - If one side is north-default and the other is south-default => expected FAIL
        #   - Otherwise => expected PASS
        expected_pass="true"
        if [[ "$from_ns" == "north-org" && "$to_ns" == "south-org" ]]; then
          expected_pass="false"
        elif [[ "$from_ns" == "south-org" && "$to_ns" == "north-org" ]]; then
          expected_pass="false"
        fi

        # Run the connectivity test
        if kubectl -n "$from_ns" exec -it "$from_pod" -- nc -zv -w1 "$to_svc" 80 ; then
          actual_pass="true"
        else
          actual_pass="false"
        fi

        # Convert booleans to PASS/FAIL for display
        if [ "$expected_pass" == "true" ]; then
          expected_str="PASS"
        else
          expected_str="FAIL"
        fi
        if [ "$actual_pass" == "true" ]; then
          actual_str="PASS"
        else
          actual_str="FAIL"
        fi

        # Compare actual vs. expected
        if [ "$actual_pass" == "$expected_pass" ]; then
          # If actual == expected => overall test is a "PASS"
          #   We'll use green text and show (expected X got X)
          echo -e "\e[32mPASS (expected $expected_str got $actual_str)\e[0m FROM ${from_ns^^}-${from_num} TO ${to_ns^^}-${to_num}"
        else
          # If mismatch => overall test is a "FAIL"
          #   We'll use red text and show (expected X got Y)
          echo -e "\e[31mFAIL (expected $expected_str got $actual_str)\e[0m FROM ${from_ns^^}-${from_num} TO ${to_ns^^}-${to_num}"
        fi

      done
    done
  done
done