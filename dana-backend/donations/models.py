from django.db import models
from django.conf import settings

class PickupLocation(models.Model):
    address = models.CharField(max_length=512)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    def __str__(self):
        return self.address[:50]

class Donation(models.Model):
    STATUS_CHOICES = (
        ('available','Available'),
        ('claimed','Claimed'),
        ('picked_up','Picked Up'),
        ('cancelled','Cancelled'),
    )
    donor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='donations')
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    location = models.ForeignKey(PickupLocation, on_delete=models.SET_NULL, null=True)
    pickup_time = models.DateTimeField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='available')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    images = models.JSONField(blank=True, null=True)  # stored as list of S3 URLs

    def __str__(self):
        return f"{self.title} - {self.donor}"


# Create your models here.
