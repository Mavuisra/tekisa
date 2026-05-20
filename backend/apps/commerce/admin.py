from django.contrib import admin

from .models import (
    Customer,
    Product,
    Sale,
    SaleItem,
    StockMovement,
    SupplierProduct,
    SupplierProfile,
    SupplierOrder,
    SupplierOrderItem,
    SupplierCallSession,
    SupplierConversation,
    SupplierMessage,
)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ("name", "sku", "seller", "unit_price", "stock_quantity", "reorder_threshold", "is_active")
    list_filter = ("is_active",)
    search_fields = ("name", "sku", "seller__username")


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ("full_name", "seller", "phone", "segment")
    search_fields = ("full_name", "phone", "seller__username")


class SaleItemInline(admin.TabularInline):
    model = SaleItem
    extra = 0


@admin.register(Sale)
class SaleAdmin(admin.ModelAdmin):
    list_display = ("id", "seller", "total", "payment_method", "status", "created_at")
    list_filter = ("payment_method", "status")
    search_fields = ("seller__username",)
    inlines = [SaleItemInline]


@admin.register(StockMovement)
class StockMovementAdmin(admin.ModelAdmin):
    list_display = ("product", "seller", "movement_type", "quantity", "reason", "balance_after", "created_at")
    list_filter = ("movement_type",)
    search_fields = ("product__name", "seller__username", "reference", "reason")


@admin.register(SupplierProfile)
class SupplierProfileAdmin(admin.ModelAdmin):
    list_display = ("business_name", "user", "business_domain", "phone", "is_active", "commune", "quarter")
    list_filter = ("is_active", "business_domain", "commune")
    search_fields = ("business_name", "phone", "user__username", "user__phone")


@admin.register(SupplierProduct)
class SupplierProductAdmin(admin.ModelAdmin):
    list_display = ("name", "supplier", "price", "is_available", "image_url")
    list_filter = ("is_available",)
    search_fields = ("name", "supplier__business_name")


class SupplierOrderItemInline(admin.TabularInline):
    model = SupplierOrderItem
    extra = 0


@admin.register(SupplierOrder)
class SupplierOrderAdmin(admin.ModelAdmin):
    list_display = ("id", "merchant", "supplier", "status", "total_amount", "created_at")
    list_filter = ("status",)
    search_fields = ("merchant__username", "supplier__business_name")
    inlines = [SupplierOrderItemInline]


@admin.register(SupplierCallSession)
class SupplierCallSessionAdmin(admin.ModelAdmin):
    list_display = ("id", "caller", "supplier", "status", "created_at", "ended_at")
    list_filter = ("status",)
    search_fields = ("caller__username", "supplier__business_name")


@admin.register(SupplierConversation)
class SupplierConversationAdmin(admin.ModelAdmin):
    list_display = ("id", "merchant", "supplier", "last_message_preview", "updated_at")
    search_fields = ("merchant__username", "supplier__business_name", "last_message_preview")


@admin.register(SupplierMessage)
class SupplierMessageAdmin(admin.ModelAdmin):
    list_display = ("id", "conversation", "sender", "message_type", "created_at")
    list_filter = ("message_type",)
    search_fields = ("conversation__supplier__business_name", "conversation__merchant__username", "content")
