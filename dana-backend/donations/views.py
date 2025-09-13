from django.shortcuts import render

from rest_framework import viewsets, permissions, filters, serializers
from .models import Donation
from .serializers import DonationSerializer
from .permissions import IsDonorOrReadOnly, IsNGOCanClaim
from rest_framework.response import Response
from rest_framework.decorators import api_view
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters


class DonationViewSet(viewsets.ModelViewSet):
    queryset = Donation.objects.all().order_by('-created_at')
    serializer_class = DonationSerializer
    permission_classes = [permissions.IsAuthenticated, IsDonorOrReadOnly, IsNGOCanClaim]

    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ["status", "donor", "ngo", "recipient", "expiry_date"]
    search_fields = ["food_type", "description", "location"]
    ordering_fields = ["created_at", "expiry_date"]

    def perform_create(self, serializer):
        serializer.save(donor=self.request.user)


    def perform_update(self, serializer):
        new_status = self.request.data.get("status")
        # NGO claims donation
        if new_status == "claimed" and self.request.user.user_type == "ngo":
            serializer.save(ngo=self.request.user, status="claimed")

        # NGO marks donation as completed (must provide recipient_id)
        elif new_status == "completed" and self.request.user.user_type == "ngo":
            recipient = serializer.validated_data.get("recipient")
            if not recipient:
                raise serializers.ValidationError({"recipient_id": "Recipient must be specified when completing a donation."})
            serializer.save(status="completed")

        # Fallback (donor edits own donation)
        else:
            serializer.save()


@api_view(['GET'])
def health_check(request):
    return Response({"status": "ok"})


# Create your views here.
