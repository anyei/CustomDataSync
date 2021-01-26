# pip3 install pyJWT cryptography requests

from datetime import datetime
import jwt
import time
import requests

# *** Update these values to match your configuration ***
IS_SANDBOX = False
KEY_FILE = 'salesforce.key'
ISSUER ='connected app client id'
SUBJECT = 'youruser@email.com'
EXPTIME = int(time.time()) + (60 * 10000)

# *******************************************************

DOMAIN = 'test' if IS_SANDBOX else 'login'

print('Loading private key...')
with open(KEY_FILE) as fd:
    private_key = fd.read()

print('Generating signed JWT assertion...')
claim = {
    'iss': ISSUER,
    'exp': EXPTIME,
    'aud': 'https://{}.salesforce.com'.format(DOMAIN),
    'sub': SUBJECT,
}
assertion = jwt.encode(claim, private_key, algorithm='RS256', headers={'alg':'RS256'})#.decode('utf8')

f = open("jwt.txt", "a")
f.write(assertion)
f.close()

print('Assertion ', assertion)

print('Making OAuth request...')
r = requests.post('https://{}.salesforce.com/services/oauth2/token'.format(DOMAIN), data = {
    'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    'assertion': assertion
})

print('Status:', r.status_code)
print(r.json())
