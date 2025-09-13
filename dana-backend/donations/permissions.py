from rest_framework import permissions

class IsDonorOrReadOnly(permissions.BasePermission):
    """
    Donors can create donations.
    NGOs/Recipients can only read or update status when applicable.
    """
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True  # anyone authenticated can view
        return request.user.user_type == "donor"

    def has_object_permission(self, request, view, obj):
        # Donor can modify their own donation
        if request.user == obj.donor:
            return True
        return request.method in permissions.SAFE_METHODS


class IsNGOCanClaim(permissions.BasePermission):
    """
    Only NGOs can claim donations.
    """
    def has_object_permission(self, request, view, obj):
        if request.method == "PATCH" and request.data.get("status") == "claimed":
            return request.user.user_type == "ngo"
        return True


class IsNGOCanClaimOrComplete(permissions.BasePermission):
    """
    NGOs can claim available donations and mark them completed.
    """
    def has_object_permission(self, request, view, obj):
        if request.method == "PATCH":
            new_status = request.data.get("status")
            if new_status == "claimed":
                return request.user.user_type == "ngo"
            if new_status == "completed":
                # Only the NGO who claimed it can complete
                return request.user.user_type == "ngo" and obj.ngo == request.user
        return True