from django.contrib import admin
from .models import *
from django.contrib.auth.admin import UserAdmin

class TheUserAdmin(UserAdmin):
    model = TheUser
    list_display = ['email', 'first_name', 'last_name', 'is_admin', 'is_staff']
    list_filter = ['is_admin', 'is_staff']
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal info', {'fields': ('first_name', 'last_name')}),
        ('Permissions', {'fields': ('is_admin', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'first_name', 'last_name', 'password1', 'password2'),
        }),
    )
    search_fields = ['email', 'first_name', 'last_name']
    ordering = ['email']

admin.site.register(TheUser, TheUserAdmin)
admin.site.register(Message)
admin.site.register(Board)
admin.site.register(Card)




