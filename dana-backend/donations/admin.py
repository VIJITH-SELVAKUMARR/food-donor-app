from django.contrib import admin
from .models import Donation, PickupLocation


admin.site.register(PickupLocation)

@admin.register(Donation)
class DonationAdmin(admin.ModelAdmin):
    list_display = ("food_type", "donor", "status", "expiry_date", "created_at")
    list_filter = ("status", "expiry_date")
    search_fields = ("food_type", "donor__username", "location")


# Register your models here.
