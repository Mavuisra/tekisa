"""
Modèles de base multi-tenant. Toutes les données sont scopées par school_id.
"""
import uuid
from django.db import models


class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class TenantModel(TimeStampedModel):
    """Modèle dont les requêtes sont filtrées par school_id."""
    school_id = models.UUIDField(db_index=True)

    class Meta:
        abstract = True
