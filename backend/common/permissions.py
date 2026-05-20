"""
Permissions basées sur rôles et multi-tenant.
"""
from rest_framework import permissions


class IsTenantScoped(permissions.BasePermission):
    """Vérifie que la ressource appartient au tenant du user."""
    def has_object_permission(self, request, view, obj):
        if not request.user.is_authenticated:
            return False
        user_tenant = getattr(request, "tenant_id", None)
        obj_tenant = getattr(obj, "tenant_id", None)
        if user_tenant is None:
            return False
        return str(obj_tenant) == str(user_tenant)


class IsAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        role = (getattr(request.user, 'role', '') or '').lower()
        return request.user.is_authenticated and role in {'admin', 'super_admin'}


class IsSeller(permissions.BasePermission):
    def has_permission(self, request, view):
        role = (getattr(request.user, 'role', '') or '').lower()
        return request.user.is_authenticated and role == 'seller'


class IsSuperAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        role = (getattr(request.user, 'role', '') or '').lower()
        return request.user.is_authenticated and role == 'super_admin'
