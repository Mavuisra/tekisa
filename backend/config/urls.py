from django.contrib import admin
from django.urls import include, path
from django.conf import settings
from django.conf.urls.static import static
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from .web_views import (
    WebAppDownloadView,
    WebAdminView,
    WebCustomersView,
    WebHomeView,
    WebIntroView,
    WebLoginView,
    WebLogoutView,
    WebRegisterView,
    WebSalesView,
    WebSettingsView,
    WebStockView,
    WebSuppliersView,
    SuperAdminDashboardView,
    SuperAdminTenantDetailPageView,
)

urlpatterns = [
    path("", WebHomeView.as_view(), name="web-home"),
    path("download/", WebAppDownloadView.as_view(), name="web-app-download"),
    path("web/intro/", WebIntroView.as_view(), name="web-intro"),
    path("web/login/", WebLoginView.as_view(), name="web-login"),
    path("web/register/", WebRegisterView.as_view(), name="web-register"),
    path("web/logout/", WebLogoutView.as_view(), name="web-logout"),
    path("web/dashboard/", WebHomeView.as_view(), name="web-dashboard"),
    path("web/ventes/", WebSalesView.as_view(), name="web-ventes"),
    path("web/stock/", WebStockView.as_view(), name="web-stock"),
    path("web/clients/", WebCustomersView.as_view(), name="web-clients"),
    path("web/fournisseurs/", WebSuppliersView.as_view(), name="web-fournisseurs"),
    path("web/administration/", WebAdminView.as_view(), name="web-administration"),
    path("web/parametres/", WebSettingsView.as_view(), name="web-parametres"),
    path("admin/", admin.site.urls),
    path("super-admin/", SuperAdminDashboardView.as_view(), name="super-admin-dashboard"),
    path(
        "super-admin/tenant/<str:tenant_id>/",
        SuperAdminTenantDetailPageView.as_view(),
        name="super-admin-tenant-detail",
    ),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
    path("api/v1/", include("config.urls_v1")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
