#!/bin/zsh

RED="\e[31m"
NORMAL="\e[0m"
GREEN="\e[92m"

export all_tests_passed=0

function build_site() {
  verbose=$1
  if orgame src/client src/pages docs; then
    printf $GREEN
    figlet 'Sito ricostruito.'
    printf $NORMAL
    
    all_tests_passed=1
  else
    printf $RED
    figlet "C'è un problema"
    printf $NORMAL
    
    all_tests_passed=0
  fi
}

function on_sourcechanges_rebuild() {
  while inotifywait -r -e modify -e move -e create -e delete -e delete_self .; do
    previous=$all_tests_passed
    test_all
    if [[ $all_tests_passed != $previous ]]; then
      if [[ $all_tests_passed == 1 ]]; then
        spd-say -y Italian+female5 'Sito ricostruito.'
      else 
        spd-say -y Italian+female5 "C'è un problema"
      fi
    fi
  done
}