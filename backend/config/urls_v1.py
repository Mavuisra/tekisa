"""Routes API sous le préfixe /api/v1/"""
from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path("token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("users/", include("apps.users.urls")),
    path("commerce/", include("apps.commerce.urls")),
]
