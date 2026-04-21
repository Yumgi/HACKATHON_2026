import os


class Config:
    SECRET_KEY = os.environ["SECRET_KEY"]
    SQLALCHEMY_DATABASE_URI = os.environ["DATABASE_URL"]
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    LDAP_URL = os.environ.get("LDAP_URL", "ldap://192.168.10.10")
    LDAP_BASE_DN = os.environ.get("LDAP_BASE_DN", "dc=acme,dc=local")
    LDAP_BIND_DN = os.environ.get("LDAP_BIND_DN", "")
    LDAP_BIND_PASSWORD = os.environ.get("LDAP_BIND_PASSWORD", "")

    LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO")
