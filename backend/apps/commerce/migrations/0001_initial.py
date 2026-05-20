from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="Customer",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("full_name", models.CharField(max_length=150)),
                ("phone", models.CharField(blank=True, max_length=32)),
                ("email", models.EmailField(blank=True, max_length=254)),
                ("segment", models.CharField(default="regular", max_length=32)),
                ("notes", models.TextField(blank=True)),
                (
                    "seller",
                    models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="commerce_customers", to=settings.AUTH_USER_MODEL),
                ),
            ],
            options={"ordering": ("full_name",)},
        ),
        migrations.CreateModel(
            name="Product",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("name", models.CharField(max_length=150)),
                ("sku", models.CharField(max_length=64)),
                ("unit_price", models.DecimalField(decimal_places=2, max_digits=12)),
                ("stock_quantity", models.IntegerField(default=0)),
                ("reorder_threshold", models.IntegerField(default=5)),
                ("is_active", models.BooleanField(default=True)),
                (
                    "seller",
                    models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="commerce_products", to=settings.AUTH_USER_MODEL),
                ),
            ],
            options={
                "ordering": ("name",),
                "unique_together": {("seller", "sku")},
            },
        ),
        migrations.CreateModel(
            name="Sale",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("subtotal", models.DecimalField(decimal_places=2, max_digits=12)),
                ("discount_amount", models.DecimalField(decimal_places=2, default=0, max_digits=12)),
                ("total", models.DecimalField(decimal_places=2, max_digits=12)),
                ("payment_method", models.CharField(default="cash", max_length=32)),
                ("status", models.CharField(default="completed", max_length=32)),
                (
                    "customer",
                    models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="sales", to="commerce.customer"),
                ),
                (
                    "seller",
                    models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="commerce_sales", to=settings.AUTH_USER_MODEL),
                ),
            ],
            options={"ordering": ("-created_at",)},
        ),
        migrations.CreateModel(
            name="StockMovement",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("movement_type", models.CharField(choices=[("in", "In"), ("out", "Out"), ("adjustment", "Adjustment")], max_length=20)),
                ("quantity", models.IntegerField()),
                ("reason", models.CharField(blank=True, max_length=120)),
                ("balance_after", models.IntegerField()),
                ("reference", models.CharField(blank=True, max_length=120)),
                (
                    "product",
                    models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="stock_movements", to="commerce.product"),
                ),
                (
                    "seller",
                    models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="stock_movements", to=settings.AUTH_USER_MODEL),
                ),
            ],
            options={"ordering": ("-created_at",)},
        ),
        migrations.CreateModel(
            name="SaleItem",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("quantity", models.PositiveIntegerField()),
                ("unit_price", models.DecimalField(decimal_places=2, max_digits=12)),
                ("line_total", models.DecimalField(decimal_places=2, max_digits=12)),
                (
                    "product",
                    models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="sale_items", to="commerce.product"),
                ),
                (
                    "sale",
                    models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="items", to="commerce.sale"),
                ),
            ],
        ),
    ]
