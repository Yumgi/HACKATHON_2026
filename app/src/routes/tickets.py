from datetime import datetime
from flask import Blueprint, request, jsonify, session
from app import db
from models.ticket import Ticket
import structlog

tickets_bp = Blueprint("tickets", __name__)
log = structlog.get_logger()


def require_auth(min_role=None):
    user = session.get("user")
    role = session.get("role")
    if not user:
        return None, jsonify({"error": "Unauthorized"}), 401
    if min_role:
        order = ["viewer", "user", "admin"]
        if order.index(role) < order.index(min_role):
            log.warning("unauthorized_access", user=user, role=role, required=min_role)
            return None, jsonify({"error": "Forbidden"}), 403
    return user, None, None


@tickets_bp.route("/", methods=["GET"])
def list_tickets():
    user, err, code = require_auth()
    if err:
        return err, code

    role = session.get("role")
    query = Ticket.query
    if role == "user":
        query = query.filter_by(created_by=user)

    tickets = query.order_by(Ticket.created_at.desc()).all()
    return jsonify([t.to_dict() for t in tickets])


@tickets_bp.route("/", methods=["POST"])
def create_ticket():
    user, err, code = require_auth(min_role="user")
    if err:
        return err, code

    data = request.get_json(silent=True) or {}
    if not data.get("title") or not data.get("description"):
        return jsonify({"error": "title and description required"}), 400

    ticket = Ticket(
        title=data["title"],
        description=data["description"],
        priority=data.get("priority", "medium"),
        created_by=user,
    )
    db.session.add(ticket)
    db.session.commit()

    log.info("ticket_create", user=user, ticket_id=ticket.id, title=ticket.title)
    return jsonify(ticket.to_dict()), 201


@tickets_bp.route("/<int:ticket_id>", methods=["GET"])
def get_ticket(ticket_id):
    user, err, code = require_auth()
    if err:
        return err, code

    ticket = Ticket.query.get_or_404(ticket_id)

    role = session.get("role")
    if role == "user" and ticket.created_by != user:
        return jsonify({"error": "Forbidden"}), 403

    return jsonify(ticket.to_dict())


@tickets_bp.route("/<int:ticket_id>", methods=["PUT"])
def update_ticket(ticket_id):
    user, err, code = require_auth(min_role="user")
    if err:
        return err, code

    ticket = Ticket.query.get_or_404(ticket_id)
    role = session.get("role")

    if role == "user" and ticket.created_by != user:
        log.warning("unauthorized_access", user=user, action="ticket_update", ticket_id=ticket_id)
        return jsonify({"error": "Forbidden"}), 403

    data = request.get_json(silent=True) or {}
    for field in ("title", "description", "priority", "assigned_to", "status"):
        if field in data:
            setattr(ticket, field, data[field])

    ticket.updated_at = datetime.utcnow()
    db.session.commit()

    log.info("ticket_update", user=user, ticket_id=ticket_id)
    return jsonify(ticket.to_dict())


@tickets_bp.route("/<int:ticket_id>/close", methods=["PATCH"])
def close_ticket(ticket_id):
    user, err, code = require_auth(min_role="user")
    if err:
        return err, code

    ticket = Ticket.query.get_or_404(ticket_id)
    ticket.status = "closed"
    ticket.closed_at = datetime.utcnow()
    db.session.commit()

    log.info("ticket_close", user=user, ticket_id=ticket_id)
    return jsonify(ticket.to_dict())


@tickets_bp.route("/<int:ticket_id>", methods=["DELETE"])
def delete_ticket(ticket_id):
    user, err, code = require_auth(min_role="admin")
    if err:
        return err, code

    ticket = Ticket.query.get_or_404(ticket_id)
    db.session.delete(ticket)
    db.session.commit()

    log.info("ticket_delete", user=user, ticket_id=ticket_id)
    return jsonify({"message": "Ticket deleted"}), 200
