from django.shortcuts import render
from rest_framework import viewsets, permissions, filters, serializers, status
from .models import Donation, PickupLocation, NGOVerification
from django.utils.timezone import now
from .serializers import DonationSerializer, NGOVerificationSerializer
from .permissions import IsDonorOrReadOnly, IsNGOCanClaim
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from firebase_admin import auth
from rest_framework.parsers import MultiPartParser, FormParser


class DonationViewSet(viewsets.ModelViewSet):
    queryset = Donation.objects.all().order_by('-created_at')
    serializer_class = DonationSerializer
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [permissions.AllowAny]


    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ["status", "donor", "ngo", "recipient", "expiry_date"]
    search_fields = ["food_type", "description", "location"]
    ordering_fields = ["created_at", "expiry_date"]

    def perform_create(self, serializer):
        user = self.request.user
        location_data = self.request.data.get("location")

        # If location is a string, create or get PickupLocation
        if isinstance(location_data, str):
            location_obj, _ = PickupLocation.objects.get_or_create(address=location_data)
        elif isinstance(location_data, dict) and "address" in location_data:
            location_obj, _ = PickupLocation.objects.get_or_create(address=location_data["address"])
        else:
            location_obj = None

        serializer.save(donor=self.request.user, location=location_obj)


    def create(self, request, *args, **kwargs):
        print("📨 Received donation POST:", request.data)
        return super().create(request, *args, **kwargs)



    def perform_update(self, serializer):
        new_status = self.request.data.get("status")

        # Any user can claim
        if new_status == "claimed":
            serializer.save(ngo=self.request.user, status="claimed")

        # Any user can complete
        elif new_status == "completed":
            recipient = serializer.validated_data.get("recipient")
            if not recipient:
                raise serializers.ValidationError({"recipient_id": "Recipient must be specified when completing a donation."})
            serializer.save(status="completed")

        else:
            serializer.save()

        def get_serializer_context(self):
            context = super().get_serializer_context()
            context['request'] = self.request
            return context


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


@api_view(["POST"])
@permission_classes([IsAdminUser])
def review_ngo(request, pk):
    """
    Admin-only: Approve or reject NGO document.
    Body: { "status": "verified" } or { "status": "rejected" }
    """
    try:
        verification = NGOVerification.objects.get(pk=pk)
    except NGOVerification.DoesNotExist:
        return Response({"error": "NGO Verification not found"}, status=status.HTTP_404_NOT_FOUND)

    new_status = request.data.get("status")
    if new_status not in ["verified", "rejected"]:
        return Response({"error": "Invalid status"}, status=status.HTTP_400_BAD_REQUEST)

    verification.status = new_status
    verification.reviewed_at = now()
    verification.save()

    return Response(NGOVerificationSerializer(verification).data, status=status.HTTP_200_OK)



@api_view(["POST"])
@permission_classes([IsAuthenticated])
def upload_ngo_doc(request):
    if "document" not in request.FILES:
        return Response({"error": "Document file required"},
                        status=status.HTTP_400_BAD_REQUEST)

    verification, created = NGOVerification.objects.get_or_create(
        user=request.user,
        defaults={"document": request.FILES["document"]}
    )

    if not created:
        verification.document = request.FILES["document"]
        verification.status = False  # reset if re-uploaded
        verification.save()

    serializer = NGOVerificationSerializer(verification)
    return Response(serializer.data, status=status.HTTP_201_CREATED)




