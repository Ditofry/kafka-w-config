mkdir ssl && cd ssl

#### SERVER ####

# Step one: Create a certificate Authority.  This will be used to sign certificates. ca-key is private, ca-cert is what we will distribute to anyone who needs proof that we're trustworthy
openssl req -new -newkey rsa:4096 -days 365 -x509 -subj "/CN=Kafka-Security-CA" -keyout ca-key -out ca-cert -nodes

# Step two: configure keystore and truststore for kafka broker, using certificates we have generated we will setup kafka broker to use SSL on port 9093
# may need to play with broker count
export SRVPASS=test1234
keytool -genkey -keystore kafka.server.keystore.jks -validity 365 -storepass $SRVPASS -keypass $SRVPASS -dname "CN=localhost" -storetype pkcs12
# optional: look at the content to verify things:
# keytool -list -v -keystore kafka.server.keystore.jks # ( then pw is the one that we exported above )

# Step 3: Get signed version of the certificate for kafka broker, so that all clients are able to verify if cert of broker is valid
keytool -keystore kafka.server.keystore.jks -certreq -file cert-file -storepass $SRVPASS -keypass $SRVPASS
# we now have file cert-file which we need to send to the CA to be signed

#step 4: sign the broker's cert, with signing request (cert-file) as input and cert-signed as output
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:$SRVPASS

# step 5: create truststore for broker
keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -storepass $SRVPASS -keypass $SRVPASS -noprompt

# Step 6 import new certificates to our keystore **around 8:15
keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file ca-cert -storepass $SRVPASS -keypass $SRVPASS -noprompt
keytool -keystore kafka.server.keystore.jks -import -file cert-signed -storepass $SRVPASS -keypass $SRVPASS -noprompt

# Step 7: we can cleanup some files
rm cert-file
rm ca-cert.srl


#### CLIENTS ####
# note on approach:  we're going to use the ca-cert here to make things "dynamic"
export CLIPASS=test1234
mkdir ../client-ssl && cd ../client-ssl

# Step one: create trust store
keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ../ssl/ca-cert -storepass $CLIPASS -keypass $CLIPASS -noprompt
# Optionally see details keytool -list -v -keystore kafka.client.truststore.jks

