#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

from __future__ import annotations

import os
import jwt
import requests
import logging
from base64 import b64decode
from cryptography.hazmat.primitives import serialization
from flask_appbuilder.security.manager import AUTH_DB, AUTH_OAUTH
from airflow import configuration as conf
from airflow.www.security import AirflowSecurityManager

##from flask_appbuilder.const import AUTH_DB

# from airflow.www.fab_security.manager import AUTH_LDAP
#from airflow.www.fab_security.manager import AUTH_OAUTH
# from airflow.www.fab_security.manager import AUTH_OID
# from airflow.www.fab_security.manager import AUTH_REMOTE_USER

log = logging.getLogger(__name__)

# SSO관련 환경변수
server_name = os.environ.get('SERVER_NAME', 'rnd6.ai-biz.net')
client_secret = os.environ.get('KEYCLOAK_CLIENT_SECRET', 'SD0lUCe4vKB8zdGDObqGjDxFqjYVwWyw')

basedir = os.path.abspath(os.path.dirname(__file__))

# Flask-WTF flag for CSRF
WTF_CSRF_ENABLED = True
WTF_CSRF_TIME_LIMIT = None

# ----------------------------------------------------
# AUTHENTICATION CONFIG
# ----------------------------------------------------
# For details on how to set up each of the following authentication, see
# http://flask-appbuilder.readthedocs.io/en/latest/security.html# authentication-methods
# for details.

# The authentication type
# AUTH_OID : Is for OpenID
# AUTH_DB : Is for database
# AUTH_LDAP : Is for LDAP
# AUTH_REMOTE_USER : Is for using REMOTE_USER from web server
# AUTH_OAUTH : Is for OAuth
##AUTH_TYPE = AUTH_DB

# 패키지 설치 필요 : pip install authlib
# 확인방법 : https://keycloak.rnd6.ai-biz.net/realms/dutchboy/.well-known/openid-configuration
#   'userinfo_url': 'https://keycloak.rnd6.ai-biz.net/realms/dutchboy/protocol/openid-connect/userinfo',

AUTH_TYPE = AUTH_OAUTH
AUTH_USER_REGISTRATION = True
AUTH_ROLES_SYNC_AT_LOGIN = True
AUTH_USER_REGISTRATION_ROLE = "Admin"
OIDC_ISSUER = f'https://keycloak.{server_name}/realms/dutchboy'

# Make sure you create these role on Keycloak
AUTH_ROLES_MAPPING = {
    "airflow-admin": ["Admin"],
    "airflow-user": ["User"],
    "airflow-viewer": ["Viewer"],
    "airflow-public": ["Public"],
    "airflow-op": ["Op"],
}

OAUTH_PROVIDERS = [{
    'name': 'keycloak',
    "icon": "fa-key",
    'token_key': 'access_token',
    'remote_app': {
        'client_id': 'airflow',
        'client_secret': f'{client_secret}',
        'server_metadata_url': f'https://keycloak.{server_name}/realms/dutchboy/.well-known/openid-configuration',
        'api_base_url': f'https://keycloak.{server_name}/realms/dutchboy/protocol/openid-connect',
        'client_kwargs': {'scope': 'openid email profile roles'},
        'access_token_url': f'https://keycloak.{server_name}/realms/dutchboy/protocol/openid-connect/token',
        'authorize_url': f'https://keycloak.{server_name}/realms/dutchboy/protocol/openid-connect/auth',
        'logout_redirect_url': f'https://keycloak.{server_name}/realms/dutchboy/protocol/openid-connect/logout?redirect_uri=https://airflow.{server_name}/logout',
        'request_token_url': None,
    },
}]
logging.error(f'https://keycloak.{server_name}/realms/dutchboy/.well-known/openid-configuration')
#        'logout_redirect_url': f'https://keycloak.{server_name}/realms/dutchboy/protocol/openid-connect/logout?redirect_uri=https://airflow.{server_name}',
#        'jwks_uri': f'https://keycloak.{server_name}/realms/dutchboy/protocol/openid-connect/certs',

# # Fetch public key
# req = requests.get(OIDC_ISSUER)
# key_der_base64 = req.json()["public_key"]
# key_der = b64decode(key_der_base64.encode())
# public_key = serialization.load_der_public_key(key_der)

# class CustomSecurityManager(AirflowSecurityManager):
#     def get_oauth_user_info(self, provider, response):
#         if provider == "keycloak":
#             token = response["access_token"]
#             me = jwt.decode(token, public_key, algorithms=["HS256", "RS256"])

#             # Extract roles from resource access
#             realm_access = me.get("realm_access", {})
#             groups = realm_access.get("roles", [])

#             log.info("groups: {0}".format(groups))

#             if not groups:
#                 groups = ["Viewer"]

#             userinfo = {
#                 "username": me.get("preferred_username"),
#                 "email": me.get("email"),
#                 "first_name": me.get("given_name"),
#                 "last_name": me.get("family_name"),
#                 "role_keys": groups,
#             }

#             log.info("user info: {0}".format(userinfo))

#             return userinfo
#         else:
#             return {}


# # Make sure to replace this with your own implementation of AirflowSecurityManager class
# SECURITY_MANAGER_CLASS = CustomSecurityManager

# Uncomment to setup Full admin role name
# AUTH_ROLE_ADMIN = 'Admin'

# Uncomment and set to desired role to enable access without authentication
# AUTH_ROLE_PUBLIC = 'Viewer'

# Will allow user self registration
# AUTH_USER_REGISTRATION = True

# The recaptcha it's automatically enabled for user self registration is active and the keys are necessary
# RECAPTCHA_PRIVATE_KEY = PRIVATE_KEY
# RECAPTCHA_PUBLIC_KEY = PUBLIC_KEY

# Config for Flask-Mail necessary for user self registration
# MAIL_SERVER = 'smtp.gmail.com'
# MAIL_USE_TLS = True
# MAIL_USERNAME = 'yourappemail@gmail.com'
# MAIL_PASSWORD = 'passwordformail'
# MAIL_DEFAULT_SENDER = 'sender@gmail.com'

# The default user self registration role
# AUTH_USER_REGISTRATION_ROLE = "Public"

# When using OAuth Auth, uncomment to setup provider(s) info
# Google OAuth example:
# OAUTH_PROVIDERS = [{
#   'name':'google',
#     'token_key':'access_token',
#     'icon':'fa-google',
#         'remote_app': {
#             'api_base_url':'https://www.googleapis.com/oauth2/v2/',
#             'client_kwargs':{
#                 'scope': 'email profile'
#             },
#             'access_token_url':'https://accounts.google.com/o/oauth2/token',
#             'authorize_url':'https://accounts.google.com/o/oauth2/auth',
#             'request_token_url': None,
#             'client_id': GOOGLE_KEY,
#             'client_secret': GOOGLE_SECRET_KEY,
#         }
# }]

# When using LDAP Auth, setup the ldap server
# AUTH_LDAP_SERVER = "ldap://ldapserver.new"

# When using OpenID Auth, uncomment to setup OpenID providers.
# example for OpenID authentication
# OPENID_PROVIDERS = [
#    { 'name': 'Yahoo', 'url': 'https://me.yahoo.com' },
#    { 'name': 'AOL', 'url': 'http://openid.aol.com/<username>' },
#    { 'name': 'Flickr', 'url': 'http://www.flickr.com/<username>' },
#    { 'name': 'MyOpenID', 'url': 'https://www.myopenid.com' }]

# ----------------------------------------------------
# Theme CONFIG
# ----------------------------------------------------
# Flask App Builder comes up with a number of predefined themes
# that you can use for Apache Airflow.
# http://flask-appbuilder.readthedocs.io/en/latest/customizing.html#changing-themes
# Please make sure to remove "navbar_color" configuration from airflow.cfg
# in order to fully utilize the theme. (or use that property in conjunction with theme)
# APP_THEME = "bootstrap-theme.css"  # default bootstrap
# APP_THEME = "amelia.css"
# APP_THEME = "cerulean.css"
# APP_THEME = "cosmo.css"
# APP_THEME = "cyborg.css"
# APP_THEME = "darkly.css"
# APP_THEME = "flatly.css"
# APP_THEME = "journal.css"
# APP_THEME = "lumen.css"
# APP_THEME = "paper.css"
# APP_THEME = "readable.css"
# APP_THEME = "sandstone.css"
# APP_THEME = "simplex.css"
# APP_THEME = "slate.css"
# APP_THEME = "solar.css"
# APP_THEME = "spacelab.css"
# APP_THEME = "superhero.css"
# APP_THEME = "united.css"
# APP_THEME = "yeti.css"
