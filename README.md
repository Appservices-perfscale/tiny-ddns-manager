Tiny dynamic DNS manager
========================

This is API service to manage list of hosts for DNSMasq. By simple
request you can create DNS record. This is not meant for any serious
deployment.

We use it just to give us handy way how to create hostnames for temporary
virtual machines and such. We use DNSMasq as an actual DNS server.


Usage
-----

Get a list of managed hostnames:

    curl -X GET http://127.0.0.1:5000/

To add or modify hostname's IP (without domain name you configured) - IP
is taken from the source of the request:

    curl -X PUT http://127.0.0.1:5000/manage/my-cool-host.usersys.example.com

To remove a hostname:

    curl -X DELETE http://127.0.0.1:5000/manage/my-cool-host.usersys.example.com

For every managed host, you should be able to see one file in `hosts_dir/`
directory. Intention is that dnsmasq would be loading hosts from that
directory, so this way you can manage hosts returned by that DNS server.


Developing
----------

This will get you the server running on `http://127.0.0.1:5000/`:

    python -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    export FLASK_APP=tdm.py
    flask run


Build image
-----------

Image should be available form quay.io repo:

    podman pull quay.io/rhcloudperfscale/tiny-ddns-manager

To build the image:

    sudo podman build -t tiny-ddns-manager .

And to run it:

    podman run --rm -ti -p 5000:5000 -v $( pwd )/hosts_dir/:/usr/src/app/hosts_dir:Z tiny-ddns-manager


Testing
-------

Ensure you do not have some server running on port 5000 and run:

    ./tests.sh
