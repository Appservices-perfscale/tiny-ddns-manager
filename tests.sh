#!/bin/sh

set -xe

rm -rf hosts_dir/
mkdir -p hosts_dir/
echo "1.2.3.4 xyz.example.com" >hosts_dir/xyz.example.com

if ! [ -d venv ]; then
    python -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
fi

source venv/bin/activate
export FLASK_APP=tdm.py
flask run &>/tmp/tdm.log &
pid=$!
trap "kill $pid" EXIT
sleep 1

curl -X GET http://127.0.0.1:5000/ | grep 'xyz\.example\.com.*1\.2\.3\.4'
curl -X GET http://127.0.0.1:5000/ | grep -v 'another-host\.example\.com'

curl -X PUT http://127.0.0.1:5000/manage/another-host.example.com | grep 'result.*success'

grep '127\.0\.0\.1 another-host\.example\.com' hosts_dir/another-host_example_com

curl -X GET http://127.0.0.1:5000/ | grep 'xyz\.example\.com.*1\.2\.3\.4'
curl -X GET http://127.0.0.1:5000/ | grep 'another-host\.example\.com.*127\.0\.0\.1'

echo "SUCCESS"
