# users/auth.py
from rest_framework import authentication, exceptions
import firebase_admin
from firebase_admin import auth as firebase_auth, credentials
from django.conf import settings
from django.contrib.auth import get_user_model

User = get_user_model()

# Initialize firebase app once
if not firebase_admin._apps:
    cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_JSON)
    firebase_admin.initialize_app(cred)

class FirebaseAuthentication(authentication.BaseAuthentication):
    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION')
        if not auth_header:
            return None
        if not auth_header.startswith('Bearer '):
            return None
        token = auth_header.split('Bearer ')[1]
        try:
            decoded = firebase_auth.verify_id_token(token)
        except Exception as e:
            raise exceptions.AuthenticationFailed('Invalid Firebase token')

        uid = decoded.get('uid')
        email = decoded.get('email')

        # Get or create local user
        user, created = User.objects.get_or_create(username=uid, defaults={'email': email})
        return (user, None)
