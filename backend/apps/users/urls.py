from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import (
    LoginView,
    RegisterView,
    RequestOTPView,
    UserViewSet,
    VerifyOTPView,
)

router = DefaultRouter()
router.register("users", UserViewSet, basename="user")

urlpatterns = [
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/register/", RegisterView.as_view(), name="register"),
    path("auth/request-otp/", RequestOTPView.as_view(), name="request-otp"),
    path("auth/verify-otp/", VerifyOTPView.as_view(), name="verify-otp"),
]

urlpatterns += router.urls

