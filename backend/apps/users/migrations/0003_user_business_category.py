from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0002_alter_user_role"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="business_category",
            field=models.CharField(
                choices=[
                    ("restaurant", "Restaurant"),
                    ("boutique", "Boutique"),
                    ("pharmacie", "Pharmacie"),
                ],
                default="boutique",
                max_length=32,
            ),
        ),
    ]
