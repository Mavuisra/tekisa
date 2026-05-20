from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("commerce", "0005_supplier_profile_enrichment_and_chat"),
    ]

    operations = [
        migrations.AddField(
            model_name="supplierproduct",
            name="source_product",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="supplier_publications",
                to="commerce.product",
            ),
        ),
    ]
