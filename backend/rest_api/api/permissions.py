from rest_framework import permissions
from .models import Card

class IsAdminOrCardMember(permissions.BasePermission):
    """
    Custom permission to allow:
    - Admins to have full access
    - Card members to read all attributes and update status
    - No access for non-members
    """
    def has_permission(self, request, view):
        # Allow authenticated users, we'll do more specific checks in has_object_permission
        return request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        # Allow admin users full access
        if getattr(request.user, 'is_admin', False):
            return True
        
        # For card members
        if isinstance(obj, Card) and request.user in obj.members.all():
            # Allow GET requests (read access)
            if request.method == 'GET' and view.action == 'list':
                return True
            # Allow PATCH requests that only update 'status'
            if request.method == 'PATCH' and set(request.data.keys()) == {'status'}:
                return True
        
        # Deny access for non-members
        return False

class IsMemberOfBoardOrAdmin(permissions.BasePermission):
    """
    Custom permission to only allow members of a board or admins to view it.
    """

    def has_permission(self, request, view):
        # Allow authenticated members to only retrieve board
        if request.method == 'GET' and view.action == 'list':
            return request.user.is_authenticated
        # Allow authenticated admins to all actions.
        return request.user.is_authenticated and getattr(request.user, 'is_admin', False)

    def has_object_permission(self, request, view, obj):
        if not request.user.is_authenticated:
            return False
        if getattr(request.user, 'is_admin', False):
            return True
        return self.is_member_of_board(request.user, obj)

    def is_member_of_board(self, user, board):
        # Check if the user is a member of any card in the board
        cards = Card.objects.filter(board=board)
        return any(user in card.members.all() for card in cards)
