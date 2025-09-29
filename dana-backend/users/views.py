from django.shortcuts import render
from rest_framework import viewsets, permissions
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters
from .models import User, NGOVerification
from .serializers import UserSerializer, NGOVerificationSerializer
from .permissions import IsAdminOrReadOnly
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ["user_type", "is_active"]
    search_fields = ["username", "email", "phone_number", "address"]
    ordering_fields = ["username", "date_joined"]


class NGOVerificationViewSet(viewsets.ModelViewSet):
    queryset = NGOVerification.objects.all()
    serializer_class = NGOVerificationSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminOrReadOnly]

    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ["verified", "user"]
    search_fields = ["user__username", "user__email"]
    ordering_fields = ["submitted_at"]


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def sync_user(request):
    firebase_user = request.user  # comes from FirebaseAuthentication
    
    user_type = request.data.get("user_type", "donor")
    phone_number = request.data.get("phone_number", "")
    address = request.data.get("address", "")

    # username = Firebase UID
    user, created = User.objects.get_or_create(
        username=request.user.username,
        defaults={
            "email": firebase_user.email,
            "user_type": user_type,
            "phone_number": phone_number,
            "address": address,
            "is_donor": (user_type == "donor"),
            "is_receiver": (user_type == "recipient"),
        }
    )

    if not created:
        # update user fields
        user.user_type = user_type
        user.phone_number = phone_number
        user.address = address
        user.is_donor = (user_type == "donor")
        user.is_receiver = (user_type == "recipient")
        user.save()

    serializer = UserSerializer(user)
    return Response({
    "status": "ok",
    "message": f"Synced user {user.email} successfully",
    "user": {
        "id": user.id,
        "email": user.email,
        "user_type": user.user_type,
    }
})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def upload_ngo_doc(request):
    if request.user.user_type != "ngo":
        return Response({"error": "Only NGOs can upload documents"},
                        status=status.HTTP_403_FORBIDDEN)

    if "document" not in request.FILES:
        return Response({"error": "Document file required"},
                        status=status.HTTP_400_BAD_REQUEST)

    verification, created = NGOVerification.objects.get_or_create(
        user=request.user,
        defaults={"document": request.FILES["document"]}
    )

    if not created:
        verification.document = request.FILES["document"]
        verification.verified = False  # reset if re-uploaded
        verification.save()

    serializer = NGOVerificationSerializer(verification)
    return Response(serializer.data, status=status.HTTP_201_CREATED)


