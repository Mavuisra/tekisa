from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    list_display = ("username", "phone", "company_name", "role", "business_category", "is_active")
    list_filter = ("role", "business_category", "company_province", "is_active", "is_staff", "is_superuser")
    search_fields = ("username", "phone", "email", "company_name", "rccm", "idnat", "nif")
    ordering = ("username",)
    fieldsets = (
        (None, {"fields": ("username", "password")}),
        (
            "Informations personnelles",
            {"fields": ("first_name", "last_name", "email", "phone", "business_category")},
        ),
        (
            "Entreprise (RDC)",
            {
                "fields": (
                    "company_name",
                    "company_trade_name",
                    "legal_form",
                    "rccm",
                    "idnat",
                    "nif",
                    "company_email",
                    "company_phone",
                    "company_country",
                    "company_province",
                    "company_city",
                    "company_commune",
                    "company_quarter",
                    "company_avenue",
                    "company_number",
                )
            },
        ),
        ("Rôle et permissions", {"fields": ("role", "is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Dates importantes", {"fields": ("last_login", "date_joined")}),
    )

