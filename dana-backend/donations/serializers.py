from rest_framework import serializers
from .models import Donation, PickupLocation
from items.serializers import FoodItemSerializer

class PickupLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = PickupLocation
        fields = '__all__'

class DonationSerializer(serializers.ModelSerializer):
    items = FoodItemSerializer(many=True, required=False)
    location = PickupLocationSerializer()

    class Meta:
        model = Donation
        fields = ['id','donor','title','description','location','pickup_time','status','items','images','created_at']
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
