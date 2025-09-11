from rest_framework import serializers
from .models import FoodItem

class FoodItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodItem
        fields = ['id','name','quantity','estimated_expiry_hours']
