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
export HOSTS_DIR=hosts_dir
export ALLOWED_DOMAIN=example.com
export FLASK_APP=tdm.py
flask run &>/tmp/tdm.log &
pid=$!
trap "kill $pid" EXIT
sleep 1

# Pre-created host exists
curl -X GET http://127.0.0.1:5000/ | grep 'xyz\.example\.com.*1\.2\.3\.4'

# We can create host and it will appear in file and in API
curl -X GET http://127.0.0.1:5000/ | grep -v 'another-host\.example\.com'
curl -X PUT http://127.0.0.1:5000/manage/another-host.example.com | grep 'result.*success'
grep '127\.0\.0\.1 another-host\.example\.com' hosts_dir/another-host_example_com
curl -X GET http://127.0.0.1:5000/ | grep 'another-host\.example\.com.*127\.0\.0\.1'

# Pre-created host still exists
curl -X GET http://127.0.0.1:5000/ | grep 'xyz\.example\.com.*1\.2\.3\.4'

# Ensure we can not create in different than allowed domain
curl -X PUT http://127.0.0.1:5000/manage/unknown-host.another.net | grep 'result.*failed'
curl -X GET http://127.0.0.1:5000/ | grep -v 'unknown-host\.another\.net'

# If there it host in incorrect domain, still list it
echo '5.6.7.8 host-from-elsewhere.elsewhere.org' >hosts_dir/host-from-elsewhere_elsewhere_org
curl -X GET http://127.0.0.1:5000/ | grep 'xyz\.example\.com.*1\.2\.3\.4'
curl -X GET http://127.0.0.1:5000/ | grep 'another-host\.example\.com.*127\.0\.0\.1'
curl -X GET http://127.0.0.1:5000/ | grep 'host-from-elsewhere\.elsewhere\.org.*5\.6\.7\.8'

# Test DELETE: Remove a host and verify it's gone
curl -X DELETE http://127.0.0.1:5000/manage/another-host.example.com | grep 'result.*success'
curl -X GET http://127.0.0.1:5000/ | grep -v 'another-host\.example\.com'
test ! -f hosts_dir/another-host_example_com

# Test DELETE: Try to remove non-existent host
curl -X DELETE http://127.0.0.1:5000/manage/does-not-exist.example.com | grep 'result.*failed'

# Verify other hosts still exist after deletion
curl -X GET http://127.0.0.1:5000/ | grep 'xyz\.example\.com.*1\.2\.3\.4'
curl -X GET http://127.0.0.1:5000/ | grep 'host-from-elsewhere\.elsewhere\.org.*5\.6\.7\.8'

echo "SUCCESS"
