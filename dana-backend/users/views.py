from django.shortcuts import render
from rest_framework import viewsets, permissions
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters
from .models import User, NGOVerification
from .serializers import UserSerializer, NGOVerificationSerializer
from .permissions import IsAdminOrReadOnly


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

# Create your views here.
