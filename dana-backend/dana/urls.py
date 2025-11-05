"""
URL configuration for dana project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from rest_framework import routers
from donations.views import DonationViewSet, health_check, review_ngo, upload_ngo_doc
from django.conf import settings
from django.conf.urls.static import static
from users.views import UserViewSet, NGOVerificationViewSet, sync_user


router = routers.DefaultRouter()
router.register('donations', DonationViewSet, basename='donation')
router.register('users', UserViewSet, basename='user')
router.register('ngo-verifications', NGOVerificationViewSet, basename='ngo-verification')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
    path('api/auth/sync/', sync_user),
    path('api/health/', health_check),
    path('api/auth/ngo-upload/', upload_ngo_doc),
    path("api/admin/ngo-review/<int:pk>/", review_ngo, name="review-ngo"),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
