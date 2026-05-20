from typing import Any

from django.db.models import QuerySet
from rest_framework.request import Request
from rest_framework.viewsets import ModelViewSet


class TenantScopedQuerySetMixin:
    """
    Enforce filtering by tenant for multi-tenant isolation.

    Assumes model has a `tenant_id` field and middleware sets `request.tenant_id`.
    """

    def get_tenant_id(self) -> Any:
        request: Request = self.request  # type: ignore[attr-defined]
        return getattr(request, "tenant_id", None)

    def get_queryset(self) -> QuerySet:
        qs = super().get_queryset()  # type: ignore[misc]
        tenant_id = self.get_tenant_id()
        if tenant_id:
            return qs.filter(tenant_id=tenant_id)
        return qs.none()

    def perform_create(self, serializer):
        serializer.save(tenant_id=self.get_tenant_id())


class TenantScopedViewSet(TenantScopedQuerySetMixin, ModelViewSet):
    """Base DRF viewset auto-scoped to tenant."""

    pass

