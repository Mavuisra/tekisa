"""
Injecte tenant_id dans la requête pour le multi-tenant.
Le front peut envoyer X-Company-ID.
"""
from django.utils.deprecation import MiddlewareMixin


class TenantMiddleware(MiddlewareMixin):
    def process_request(self, request):
        tenant_id = (
            request.headers.get('X-Company-ID')
            or request.META.get('HTTP_X_COMPANY_ID')
        )
        request.tenant_id = tenant_id
