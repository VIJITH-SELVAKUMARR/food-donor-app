from django.db import models
from django.conf import settings
from users.models import User

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
        ('completed', 'Completed'),
        ('expired', 'Expired'),
    )
    donor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='donations', limit_choices_to={'user_type': 'donor'})
    ngo = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='donations_collected', limit_choices_to={'user_type': 'ngo'})
    recipient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='donations_received', limit_choices_to={'user_type': 'recipient'})

    food_type = models.CharField(max_length=100, null=True, blank=True)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    expiry_date = models.DateField(null=True, blank=True)
    location = models.ForeignKey(PickupLocation, on_delete=models.SET_NULL, null=True)

    pickup_time = models.DateTimeField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='available')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    images = models.JSONField(blank=True, null=True)  # stored as list of S3 URLs

    def __str__(self):
        return f"{self.food_type} by {self.donor.username} ({self.status})"
    

class NGOVerification(models.Model):
    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("verified", "Verified"),
        ("rejected", "Rejected"),
    ]

    ngo = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="ngo_verification"
    )
    document = models.FileField(upload_to="ngo_docs/")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    submitted_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.ngo.email} - {self.status}"