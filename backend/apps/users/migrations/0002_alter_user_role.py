from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0001_initial"),
    ]

    operations = [
        migrations.AlterField(
            model_name="user",
            name="role",
            field=models.CharField(
                choices=[
                    ("super_admin", "Super admin"),
                    ("school_admin", "School admin"),
                    ("seller", "Seller"),
                    ("teacher", "Teacher"),
                    ("parent", "Parent"),
                    ("student", "Student"),
                ],
                default="seller",
                max_length=32,
            ),
        ),
    ]
