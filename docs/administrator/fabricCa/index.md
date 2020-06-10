# Useful fabric-ca commands

To use a command against the fabric-ca we have to set up some TLS environment variables.

```bash 
export FABRIC_CA_CLIENT_HOME=./ca/client/tls-admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=./ca-tls.morgen.net.cert.pem
```

Shows a list of all available identities.
```bash
 fabric-ca-client identity list
```

Shows a specific identity.
```bash
fabric-ca-client identity list --id ca-mars.morgen.net-admin
``` 

### Check if an identity is registered or enrolled 

To check if an identity is registerd, you can use the following command. If the command shows the identity, then it is registered.

```bash
fabric-ca-client identity list --id user1-mars.morgen.net

# shows something like this
Name: user1-mars.morgen.net, Type: client, Affiliation: , Max Enrollments: -1, Attributes: [{Name:hf.EnrollmentID Value:user1-mars.morgen.net ECert:true} {Name:hf.Type Value:client ECert:true} {Name:hf.Affiliation Value: ECert:true}]
```

If the identity is only registered and not enrolled. You will receive no result like it is displayed in the example below.

```bash
fabric-ca-client certificate list --id user1-mars.morgen.net

# shows something like this
No results returned
```

### Check the validity of a enrolled identity
```bash
openssl x509 -in admin/msp/cacerts/ca-mars-morgen-net-7054.pem -text

# should show something like that
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            58:34:5d:77:8c:10:18:e5:cd:e2:93:25:48:e0:25:3b:07:a4:a4:21
        Signature Algorithm: ecdsa-with-SHA256
        Issuer: C = US, ST = North Carolina, O = Hyperledger, OU = Fabric, CN = ca-mars.morgen.net
        Validity
            Not Before: Jun  4 14:19:00 2020 GMT
            Not After : Jun  1 14:19:00 2035 GMT
        Subject: C = US, ST = North Carolina, O = Hyperledger, OU = Fabric, CN = ca-mars.morgen.net
```
