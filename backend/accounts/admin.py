from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User
from .models import UserProfile


class UserProfileInline(admin.StackedInline):
    model = UserProfile
    can_delete = False
    verbose_name_plural = 'Profile'
    fields = ('avatar', 'bio', 'location', 'birth_date', 'preferred_confidence_threshold', 'email_notifications')


class UserAdmin(BaseUserAdmin):
    inlines = (UserProfileInline,)
    list_display = ('username', 'email', 'first_name', 'last_name', 'is_staff', 'date_joined', 'get_detection_count')
    list_filter = ('is_staff', 'is_superuser', 'is_active', 'date_joined')
    
    def get_detection_count(self, obj):
        return obj.profile.detection_count if hasattr(obj, 'profile') else 0
    get_detection_count.short_description = 'Detections'


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'location', 'detection_count', 'preferred_confidence_threshold', 'created_at')
    list_filter = ('email_notifications', 'created_at')
    search_fields = ('user__username', 'user__email', 'location')
    readonly_fields = ('created_at', 'updated_at', 'detection_count')


# Re-register UserAdmin
admin.site.unregister(User)
admin.site.register(User, UserAdmin) 