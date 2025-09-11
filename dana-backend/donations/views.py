from django.shortcuts import render

from rest_framework import viewsets, permissions
from .models import Donation
from .serializers import DonationSerializer

class DonationViewSet(viewsets.ModelViewSet):
    queryset = Donation.objects.all().order_by('-created_at')
    serializer_class = DonationSerializer

    def perform_create(self, serializer):
        serializer.save(donor=self.request.user)


# Create your views here.
