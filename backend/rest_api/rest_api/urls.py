"""rest_api URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/3.2/topics/http/urls/
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
from django.conf import settings
from django.conf.urls.static import static
from django.urls import path, include
from rest_framework_simplejwt.views import (
    TokenRefreshView,
    TokenVerifyView
)
from api.views import SignupView, SignInView, AsgiValidateTokenView


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/',include('api.urls')),
    path('api/signup/', SignupView.as_view(), name='signup'),
    path('api/signin/', SignInView.as_view(), name='get_token'),
    path('api/signin/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/signin/verify/', TokenVerifyView.as_view(), name='token_verify'),
    path('api/ws_auth_uuid/', AsgiValidateTokenView.as_view(), name='get_ws_auth_uuid')
]

# TODO: Image serving in production mode
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)