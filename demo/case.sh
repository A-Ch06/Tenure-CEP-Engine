#!/bin/sh
# Plays the users of the PAIS for one tenure-track case.
# Usage: case.sh setup | finish
P=${PAIS:-http://pais:8090}
S=${SIDDHI:-http://siddhi:8006}
C=case1

wait_for() {  # wait until a URL answers at all
  until [ "$(curl -s -o /dev/null -w '%{http_code}' "$1")" != "000" ]; do sleep 2; done
}

if [ "$1" = "setup" ]; then
  echo "Waiting for PAIS and Siddhi..."
  wait_for "$P/health"; wait_for "$S/dcr-events"
  curl -s -XPOST "$P/cases" -d '{"caseId":"'$C'","authorId":"A5069386704","start":"2021-01-01"}'
  for e in start plan mentor vision udtu portfolio midterm; do
    curl -s -o /dev/null -XPOST "$P/cases/$C/events/$e"
  done
  curl -s -XPOST "$P/cases/$C/advance" -d '{"days":1827}'
  echo "Request assessment:";              curl -s -XPOST "$P/cases/$C/events/req"
  echo "Assessment before research output:"; curl -s -XPOST "$P/cases/$C/events/a1"
fi

if [ "$1" = "finish" ]; then
  echo "Waiting for research output to unblock the assessment..."
  until [ "$(curl -s -o /dev/null -w '%{http_code}' -XPOST "$P/cases/$C/events/a1")" = "200" ]; do sleep 2; done
  echo "First academic assessment executed"
  curl -s -XPOST "$P/cases/$C/events/q1"
  curl -s -XPOST "$P/cases/$C/events/transfer"
  mkdir -p /output && curl -s "$P/log.xes" > /output/p4_log.xes
  echo "Event log written to output/p4_log.xes"
fi
