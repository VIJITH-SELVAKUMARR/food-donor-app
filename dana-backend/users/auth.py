# users/auth.py
from firebase_admin import auth as firebase_auth
from rest_framework import authentication, exceptions
from django.contrib.auth import get_user_model

User = get_user_model()

class FirebaseAuthentication(authentication.BaseAuthentication):
    def authenticate(self, request):
        auth_header = request.META.get("HTTP_AUTHORIZATION")
        if not auth_header:
            return None

        parts = auth_header.split()
        if parts[0].lower() != "bearer" or len(parts) != 2:
            return None

        id_token = parts[1]
        try:
            decoded_token = firebase_auth.verify_id_token(id_token)
        except Exception:
            raise exceptions.AuthenticationFailed("Invalid Firebase ID token")

        uid = decoded_token.get("uid")
        email = decoded_token.get("email")

        # Get or create local user
        user, _ = User.objects.get_or_create(
            email=email,
            defaults={"username": email.split("@")[0], "user_type": "donor"},
        )

        return (user, None)
