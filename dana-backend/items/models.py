from django.db import models
from donations.models import Donation

class FoodItem(models.Model):
    donation = models.ForeignKey(Donation, related_name='items', on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    quantity = models.CharField(max_length=100)  # flexible: "2 boxes", "5 kg"
    estimated_expiry_hours = models.IntegerField(null=True, blank=True)

    def __str__(self):
        return f"{self.name} ({self.quantity})"


# Create your models here.
