from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, NGOVerification


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ("username", "email", "user_type", "is_active", "is_staff")
    list_filter = ("user_type", "is_active", "is_staff")
    search_fields = ("username", "email")


@admin.register(NGOVerification)
class NGOVerificationAdmin(admin.ModelAdmin):
    list_display = ("user", "verified", "submitted_at")
    list_filter = ("verified",)
    search_fields = ("user__username", "user__email")


# Register your models here.
