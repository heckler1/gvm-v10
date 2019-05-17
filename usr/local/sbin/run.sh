#!/bin/bash

# Set our password based on the environment variable
# Defaults to "admin"
GVM_PASSWORD=${GVM_PASSWORD:-admin}
ADDRESS=127.0.0.1
KEY_FILE=/var/lib/gvm/private/CA/clientkey.pem
CERT_FILE=/var/lib/gvm/CA/clientcert.pem
CA_FILE=/var/lib/gvm/CA/cacert.pem

# Start our redis server
redis-server /etc/redis.conf &

# Wait for Redis to come up
echo "Testing redis status..."
X="$(redis-cli -s /tmp/redis.sock ping 2> /dev/null)"
while  [ "${X}" != "PONG" ]; do
        echo "Redis not yet ready..."
        sleep 1
        X="$(redis-cli -s /tmp/redis.sock ping)"
done
echo "Redis ready."

# Check certs
if [ ! -f /var/lib/gvm/CA/cacert.pem ]
then
	/usr/bin/gvm-manage-certs -a
fi

# Update our feeds on startup
# This will take a long time if the container is not regularly rebuilt
sh /usr/local/sbin/update_feeds.sh

if [ ! -d /usr/share/openvas/gsa/locale ]
then
	mkdir -p /usr/share/openvas/gsa/locale
fi

echo "Restarting services..."
/usr/sbin/openvassd
/usr/sbin/gvmd
/usr/sbin/gsad

echo
echo -n "Checking for scanners: "
SCANNER=$(/usr/sbin/gvmd --get-scanners)
echo "Done"

if ! (echo "${SCANNER}" | grep -q nmap)
then
        echo "Adding nmap scanner"
        /usr/bin/ospd-nmap \
				  --bind-address ${ADDRESS} \
					--port 40001 \
					--key-file ${KEY_FILE} \
					--cert-file ${CERT_FILE} \
					--ca-file ${CA_FILE} &
        /usr/sbin/gvmd \
				  --create-scanner=ospd-nmap \
					--scanner-host=localhost \
					--scanner-port=40001 \
					--scanner-type=OSP \
					--scanner-ca-pub=${CA_FILE} \
					--scanner-key-pub=${CERT_FILE} \
					--scanner-key-priv=${KEY_FILE}
        echo
else
	/usr/bin/ospd-nmap \
	  --bind-address ${ADDRESS} \
		--port 40001 \
		--key-file ${KEY_FILE} \
		--cert-file ${CERT_FILE} \
		--ca-file ${CA_FILE} &

fi

# Check for users, and create admin
if [[ "$(gvmd --get-users)" = "" ]]
then
	echo "Setting up admin user..."
	/usr/sbin/gvmd gvmd --create-user=admin
	/usr/sbin/gvmd --user=admin --new-password="${GVM_PASSWORD}"
fi

# If the password is not the default value, we should reset it to what the user wants
if [ "${GVM_PASSWORD}" != "admin" ]
then
	echo "Setting admin password..."
	/usr/sbin/gvmd --user=admin --new-password="${GVM_PASSWORD}"
fi


if [ -z "${BUILD}" ]
then
	echo "Tailing logs..."
	tail -F /var/log/gvm/*
fi

