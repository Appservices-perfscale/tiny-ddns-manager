#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os
import re
import socket

import flask


app = flask.Flask(__name__)

HOSTS_DIR = os.environ.get('HOSTS_DIR', 'hosts_dir/')
ALLOWED_DOMAIN = os.environ.get('ALLOWED_DOMAIN', 'example.com')


def _validate_ip(data):
    """Make sure this is IPv4 address.

    Taken from https://stackoverflow.com/questions/319279/how-to-validate-ip-address-in-python"""

    socket.inet_pton(socket.AF_INET, data)
    return data


def _sanitize_hostname(data):
    """Just sanitize hostname into unified form"""
    # Strip exactly one dot from the right, if present
    if data[-1] == ".":
        data = data[:-1]

    # Make it lowercase
    data = data.lower()

    return data


def _validate_hostname(data):
    """Make sure this is suitable for hostname.

    Taken from https://stackoverflow.com/questions/2532053/validate-a-hostname-string"""
    data = _sanitize_hostname(data)

    assert len(data) <= 255, f"Too long hostname {data}: {len(data)} chars"

    # Ensures that each segment:
    #  - contains at least one character and a maximum of 63 characters
    #  - consists only of allowed characters
    #  - doesn't begin or end with a hyphen
    allowed = re.compile("(?!-)[a-z0-9-]{1,63}(?<!-)$")
    assert all(allowed.match(x) for x in data.split(".")), "Hostname segment is not valid"

    # Ensure hostname is from allowed domain
    assert data.endswith('.' + ALLOWED_DOMAIN), "Hostname have to be in allowed domain"

    return data


def _load_hosts():
    """Load hosts in hosts directory."""

    hosts = {}

    for f in os.listdir(HOSTS_DIR):
        f_path = os.path.join(HOSTS_DIR, f)
        if os.path.isfile(f_path):
            with open(f_path, 'r') as fp:
                for line in fp:
                    line = line.strip()
                    if line == '' or line.startswith('#'):
                        continue

                    ip, hostname = line.split()

                    hostname = _sanitize_hostname(hostname)
                    ip = _validate_ip(ip)

                    assert hostname not in hosts, f"Hostname {hostname} duplicated"
                    hosts[hostname] = ip

    return hosts


def _manage_host(hostname, ip):
    """Add host to the directory"""

    hostname = _validate_hostname(hostname)
    ip = _validate_ip(ip)

    hostname_safe = re.sub(r'[^a-z0-9_-]', '_', hostname.lower())
    f_path = os.path.join(HOSTS_DIR, hostname_safe)
    with open(f_path, 'w') as fp:
        fp.write(f"{ip} {hostname}")

    return f"Host {hostname} with IP {ip} added"


def _remove_host(hostname):
    """Remove host from the directory"""

    hostname = _validate_hostname(hostname)

    hostname_safe = re.sub(r'[^a-z0-9_-]', '_', hostname.lower())
    f_path = os.path.join(HOSTS_DIR, hostname_safe)

    if os.path.exists(f_path):
        os.remove(f_path)
        return f"Host {hostname} removed"
    else:
        raise FileNotFoundError(f"Host {hostname} not found")


@app.route('/', methods=['GET'])
def index():
    """Return dict with managed hosts."""

    try:
        hosts = _load_hosts()

        app.logger.debug(f"Listing {len(hosts)} hosts")
        return hosts
    except Exception as e:
        return {
            "result": "failed",
            "message": str(e),
        }, 500


@app.route('/manage/<string:hostname>', methods=['PUT'])
def manage(hostname):
    """Add or modify host."""

    try:
        ip = flask.request.remote_addr

        message = _manage_host(hostname, ip)

        return {
            "result": "success",
            "message": message,
        }
    except Exception as e:
        return {
            "result": "failed",
            "message": str(e),
        }, 500


@app.route('/manage/<string:hostname>', methods=['DELETE'])
def remove(hostname):
    """Remove host."""

    try:
        message = _remove_host(hostname)

        return {
            "result": "success",
            "message": message,
        }
    except Exception as e:
        return {
            "result": "failed",
            "message": str(e),
        }, 500
