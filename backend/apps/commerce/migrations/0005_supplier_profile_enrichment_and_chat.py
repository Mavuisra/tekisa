from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("commerce", "0004_supplier_orders_and_calls"),
    ]

    operations = [
        migrations.AddField(
            model_name="supplierproduct",
            name="image_url",
            field=models.URLField(blank=True),
        ),
        migrations.AddField(
            model_name="supplierprofile",
            name="avenue",
            field=models.CharField(blank=True, max_length=128),
        ),
        migrations.AddField(
            model_name="supplierprofile",
            name="business_domain",
            field=models.CharField(
                choices=[
                    ("restaurant", "Restaurant"),
                    ("pharmacy", "Pharmacy"),
                    ("boutique", "Boutique"),
                    ("supermarket", "Supermarket"),
                    ("hardware", "Quincaillerie"),
                    ("cosmetics", "Cosmetiques"),
                    ("electronics", "Electronique"),
                    ("other", "Autre"),
                ],
                default="other",
                max_length=32,
            ),
        ),
        migrations.AddField(
            model_name="supplierprofile",
            name="cover_image_url",
            field=models.URLField(blank=True),
        ),
        migrations.AddField(
            model_name="supplierprofile",
            name="profile_image_url",
            field=models.URLField(blank=True),
        ),
        migrations.AddField(
            model_name="supplierprofile",
            name="quarter",
            field=models.CharField(blank=True, max_length=128),
        ),
        migrations.AddField(
            model_name="supplierprofile",
            name="support_whatsapp",
            field=models.CharField(blank=True, max_length=32),
        ),
        migrations.CreateModel(
            name="SupplierConversation",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("last_message_preview", models.CharField(blank=True, max_length=240)),
                (
                    "merchant",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="supplier_conversations_started",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
                (
                    "supplier",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="conversations",
                        to="commerce.supplierprofile",
                    ),
                ),
            ],
            options={
                "ordering": ("-updated_at",),
                "unique_together": {("merchant", "supplier")},
            },
        ),
        migrations.CreateModel(
            name="SupplierMessage",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "message_type",
                    models.CharField(
                        choices=[("text", "Text"), ("voice", "Voice")],
                        default="text",
                        max_length=16,
                    ),
                ),
                ("content", models.TextField(blank=True)),
                ("voice_url", models.URLField(blank=True)),
                (
                    "conversation",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="messages",
                        to="commerce.supplierconversation",
                    ),
                ),
                (
                    "sender",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="supplier_messages_sent",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "ordering": ("created_at",),
            },
        ),
    ]
