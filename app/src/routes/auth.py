from flask import Blueprint, request, jsonify, session, current_app
from flask_login import login_user, logout_user, current_user
from ldap3 import Server, Connection, ALL, NTLM
from ldap3.core.exceptions import LDAPException
import structlog

auth_bp = Blueprint("auth", __name__)
log = structlog.get_logger()


def ldap_authenticate(username, password):
    cfg = current_app.config
    server = Server(cfg["LDAP_URL"], get_info=ALL)
    user_dn = f"uid={username},cn=users,cn=accounts,{cfg['LDAP_BASE_DN']}"

    try:
        conn = Connection(server, user=user_dn, password=password, auto_bind=True)

        conn.search(
            search_base=cfg["LDAP_BASE_DN"],
            search_filter=f"(uid={username})",
            attributes=["memberOf", "mail", "cn"],
        )

        if not conn.entries:
            return None, []

        entry = conn.entries[0]
        groups = [g.split(",")[0].replace("cn=", "") for g in entry.memberOf]
        conn.unbind()
        return {"uid": username, "cn": str(entry.cn), "mail": str(entry.mail)}, groups

    except LDAPException as e:
        log.warning("ldap_auth_failed", username=username, error=str(e))
        return None, []


def get_role_from_groups(groups):
    if "acme-admins" in groups:
        return "admin"
    if "acme-users" in groups:
        return "user"
    if "acme-readonly" in groups:
        return "viewer"
    return None


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    password = data.get("password", "")
    remote_ip = request.remote_addr

    if not username or not password:
        return jsonify({"error": "Username and password required"}), 400

    user_info, groups = ldap_authenticate(username, password)

    if not user_info:
        log.warning("login_failure", user=username, ip=remote_ip)
        return jsonify({"error": "Invalid credentials"}), 401

    role = get_role_from_groups(groups)
    if not role:
        log.warning("login_no_role", user=username, groups=groups, ip=remote_ip)
        return jsonify({"error": "No authorized group"}), 403

    session["user"] = username
    session["role"] = role
    session["cn"] = user_info["cn"]

    log.info("login_success", user=username, role=role, ip=remote_ip)
    return jsonify({"message": "Logged in", "user": username, "role": role})


@auth_bp.route("/logout", methods=["POST"])
def logout():
    user = session.get("user", "unknown")
    session.clear()
    log.info("logout", user=user, ip=request.remote_addr)
    return jsonify({"message": "Logged out"})
