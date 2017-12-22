#!/bin/bash
cmd=$1
service=$2
key=$3

getPass() {
  osascript -l JavaScript getPass.scpt
}

initData() {
  pass=$(osascript -l JavaScript confirmInit.scpt)
  if [ -z "$pass" ]; then
    echo 'Init canceled.'
    exit 1
  fi

  rm -f mfa.key mfa.crt mfalist.dat services.txt
  openssl req -x509 -sha256 -days 3650 -subj '/' -newkey rsa:2048 -passout pass:"$pass" -keyout mfa.key -out mfa.crt > /dev/null 2>&1
  touch services.txt

  echo "Initialized!"
}

addService() {
  pass=$(getPass)
  if [ -z "$pass" ]; then
    echo 'Add canceled.'
    exit 1
  fi

  ret=$(echo $pass | ./mfacodegen -a $service,$key)
  if [ $? -ne 0 ]; then
    echo "$ret" | head -n 1
    exit 1
  fi
  echo "$ret"

  echo $pass | ./mfacodegen -l > services.txt
}

generateServiceList() {
  pass=$(getPass)
  if [ -z "$pass" ]; then
    echo 'List canceled.'
    exit 1
  fi

  ret=$(echo $pass | ./mfacodegen -l 2>&1)
  if [ $? -ne 0 ]; then
    echo "$ret" | head -n 1
    exit 1
  fi
  echo "$ret" > services.txt

  echo "list generated."
}

generateToken() {
  pass=$(getPass)
  if [ -z "$pass" ]; then
    echo 'Generate canceled.'
    exit 1
  fi

  ret=$(echo $pass | ./mfacodegen -s $service 2>&1)
  if [ $? -ne 0 ]; then
    echo "$ret" | head -n 1
    exit 1
  fi

  data=''
  if [ -f ./services.txt ]; then
    data=$(egrep -v "^${service}\$" ./services.txt)
  fi
  (echo "$service"; echo "$data") > services.txt

  echo -n $ret
}

removeService() {
  pass=$(getPass)
  if [ -z "$pass" ]; then
    echo 'Remove canceled.'
    exit 1
  fi

  ret=$(echo $pass | ./mfacodegen -d $service)
  if [ $? -ne 0 ]; then
    echo "$ret" | head -n 1
    exit 1
  fi
  echo "$ret"

  echo $pass | ./mfacodegen -l > services.txt
}

filter() {
  services=($(grep "$service" "./services.txt"))

  arr=()
  for s in ${services[@]}; do
    arr+=("$(cat << EOI
      {
        "arg": "$s",
        "title": "$s",
        "subtitle": "generate MFA token for $s",
        "autocomplete": "$s"
      }
EOI
    )")
  done

  echo '{"items": ['
  (IFS=','; echo "${arr[*]}")
  echo ']}'
}

case "$cmd" in
  'init' )
    initData
    ;;
  'listgen' )
    generateServiceList
    ;;
  'add' )
    addService
    ;;
  'rm' )
    removeService
    ;;
  'filter' )
    filter
    ;;
  'token' )
    generateToken
    ;;
esac
