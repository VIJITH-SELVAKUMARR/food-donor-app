from rest_framework import serializers
from .models import Donation, PickupLocation, NGOVerification
from items.serializers import FoodItemSerializer
from users.serializers import UserSerializer
from users.models import User

class PickupLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = PickupLocation
        fields = '__all__'

class DonationSerializer(serializers.ModelSerializer):
    donor = UserSerializer(read_only=True)
    ngo = UserSerializer(read_only=True)
    recipient = UserSerializer(read_only=True)
    items = FoodItemSerializer(many=True, required=False)
    location = PickupLocationSerializer()

    recipient_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(user_type="recipient"),
        source="recipient",
        write_only=True,
        required=False
    )

    class Meta:
        model = Donation
        fields = ['id','donor',"ngo", "recipient",
                  "food_type",'title','description',"expiry_date",'location','pickup_time',
                  'status','items','images','created_at', "updated_at"]
        read_only_fields = ['donor','status','created_at']

    def create(self, validated_data):
        location_data = validated_data.pop('location')
        items_data = validated_data.pop('items', [])
        location = PickupLocation.objects.create(**location_data)
        donation = Donation.objects.create(location=location, **validated_data)
        for item in items_data:
            from items.models import FoodItem
            FoodItem.objects.create(donation=donation, **item)
        return donation



class NGOVerificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = NGOVerification
        fields = ["id", "ngo", "document", "status", "submitted_at", "reviewed_at"]
        read_only_fields = ["ngo", "submitted_at", "reviewed_at"]

