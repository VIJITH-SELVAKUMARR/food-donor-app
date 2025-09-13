from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):

    USER_TYPES = [
        ('donor', 'Donor'),
        ('ngo', 'NGO'),
        ('recipient', 'Recipient'),
    ]

    # keep username as Firebase uid — optional extra fields:
    user_type = models.CharField(max_length=20, choices=USER_TYPES, default="donor")
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    is_donor = models.BooleanField(default=False)
    is_receiver = models.BooleanField(default=False)
    address = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"{self.username} ({self.get_user_type_display()})"


class NGOVerification(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, limit_choices_to={'user_type': 'ngo'})
    document = models.FileField(upload_to="ngo_docs/")
    verified = models.BooleanField(default=False)
    submitted_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"NGO Verification - {self.user.username} ({'Verified' if self.verified else 'Pending'})"


# Create your models here.
