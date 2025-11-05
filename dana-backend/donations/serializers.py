from rest_framework import serializers
from .models import Donation, PickupLocation, NGOVerification
from items.serializers import FoodItemSerializer
from users.serializers import UserSerializer
from users.models import User

class PickupLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = PickupLocation
        fields = ["id", "address", "latitude", "longitude"]


class DonationSerializer(serializers.ModelSerializer):
    donor = UserSerializer(read_only=True)
    ngo = UserSerializer(read_only=True)
    recipient = UserSerializer(read_only=True)
    items = FoodItemSerializer(many=True, required=False)
    location = PickupLocationSerializer(required=False, allow_null=True)

    recipient_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(user_type="recipient"),
        source="recipient",
        write_only=True,
        required=False
    )

    class Meta:
        model = Donation
        fields = "__all__"

    def create(self, validated_data):
        # Extract location from either nested dict or flattened keys
        request = self.context.get("request")
        data = getattr(request, "data", {})

        # Remove donor if somehow included
        validated_data.pop("donor", None)

        location_data = validated_data.pop("location", None)
        if not location_data:
            # Support flattened frontend fields
            address = data.get("location.address")
            lat = data.get("location.latitude")
            lng = data.get("location.longitude")

            if address and lat and lng:
                location_data = {
                    "address": address,
                    "latitude": lat,
                    "longitude": lng
                }

        location = None
        if location_data:
            location = PickupLocation.objects.create(**location_data)

        # Create donation instance
        donation = Donation.objects.create(
            donor=request.user,
            location=location,
            **validated_data
        )

        return donation



class NGOVerificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = NGOVerification
        fields = ["id", "user", "document", "status", "submitted_at", "reviewed_at"]
        read_only_fields = ["user", "submitted_at", "reviewed_at"]

    

