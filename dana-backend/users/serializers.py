from rest_framework import serializers
from .models import User, NGOVerification

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email", "phone_number", "address", "user_type", "firebase_uid","is_donor", "is_receiver",]


class NGOVerificationSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = NGOVerification
        fields = ["id", "user", "document", "verified", "submitted_at"]
        read_only_fields = ["verified", "submitted_at", "user"]
