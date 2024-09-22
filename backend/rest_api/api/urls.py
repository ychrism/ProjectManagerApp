from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import BoardViewSet, CardViewSet, TheUserViewSet, SignupView
import pprint

router = DefaultRouter()
router.register(r'boards', BoardViewSet, basename='boards')
router.register(r'cards', CardViewSet, basename='cards')
router.register(r'users', TheUserViewSet, basename='users')

urlpatterns = router.urls