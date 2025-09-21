from django.shortcuts import render
from rest_framework import viewsets, permissions, filters, serializers
from .models import Donation
from .serializers import DonationSerializer
from .permissions import IsDonorOrReadOnly, IsNGOCanClaim
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters
from rest_framework.permissions import AllowAny
from firebase_admin import auth
from rest_framework import status


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
@permission_classes([AllowAny])
def health_check(request):
    # Extract token from Authorization header
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return Response({"error": "Missing or invalid Authorization header"},
                        status=status.HTTP_401_UNAUTHORIZED)

    id_token = auth_header.split(" ")[1]

    try:
        # Verify the token with Firebase
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token["uid"]
        email = decoded_token.get("email")

        return Response({
            "status": "ok",
            "message": f"Hello {email}, API is secure & working",
            "uid": uid,
        })

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_401_UNAUTHORIZED)

# Create your views here.
