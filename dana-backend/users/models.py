from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    # keep username as Firebase uid — optional extra fields:
    phone = models.CharField(max_length=20, blank=True, null=True)
    is_donor = models.BooleanField(default=False)
    is_receiver = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.username} ({self.email})"


# Create your models here.
