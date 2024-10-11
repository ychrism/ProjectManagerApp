from django.db import models
from django.forms.models import model_to_dict
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
from django.db.models.fields.files import ImageFieldFile, FieldFile
from django.utils import timezone
from datetime import datetime



class TheUserManager(BaseUserManager):
    def create_user(self, email, first_name, last_name, password=None):
        if not email:
            raise ValueError("Users must have an email address")
        user = self.model(
            email=self.normalize_email(email),
            first_name=first_name,
            last_name=last_name,
        )
        user.set_password(password)
        user.save(using=self._db)
        return user

    # TODO: Seperate admin from superuser. Every user will have admin rights in their own workspaces
    def create_admin(self, email, first_name, last_name, password=None):
        user = self.create_user(
            email,
            password=password,
            first_name=first_name,
            last_name=last_name
        )
        user.is_admin = True
        user.is_staff = True
        user.save(using=self._db)
        return user


class TheUser(AbstractBaseUser):
    id = models.AutoField(primary_key=True)
    first_name = models.CharField(max_length=30)
    last_name = models.CharField(max_length=30)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=128)
    is_admin = models.BooleanField(default=False)
    is_staff = models.BooleanField(default=False)

    objects = TheUserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    def __str__(self):
        return f"{self.first_name} {self.last_name}"

    
    def to_dict(self):
        data = model_to_dict(self, fields=[field.name for field in self._meta.fields])
        
        for key, value in data.items():
            if isinstance(value, datetime):
                # Convert datetime fields to ISO format strings
                data[key] = value.isoformat()
            elif isinstance(value, (ImageFieldFile, FieldFile)):
                # Handle ImageFileField and FileField
                if value:
                    data[key] = value.url
                else:
                    data[key] = None
        
        return data


def get_due_date(weeks=1):
    return timezone.now() + timezone.timedelta(weeks=10)

class Board(models.Model):
    id = models.AutoField(primary_key=True)
    name = models.CharField(unique=True, max_length=100)
    start_date = models.DateTimeField(default=timezone.now)
    due_date = models.DateTimeField(default=get_due_date(weeks=10))
    description = models.TextField(default='This is a new board')
    progress = models.FloatField(default=0)
    pic = models.ImageField(upload_to='uploads/images/', null=True, blank=True)
    members = models.ManyToManyField(TheUser, related_name="boards", blank=True) # unique

    def __str__(self):
        return self.name

    def to_dict(self):
        data = model_to_dict(self, fields=[field.name for field in self._meta.fields])
        
        for key, value in data.items():
            if isinstance(value, datetime):
                # Convert datetime fields to ISO format strings
                data[key] = value.isoformat()
            elif isinstance(value, (ImageFieldFile, FieldFile)):
                # Handle ImageFileField and FileField
                if value:
                    data[key] = value.url
                else:
                    data[key] = None
        
        return data


class CardPriority(models.TextChoices):
    LOW = 'LOW', 'Low'
    MEDIUM = 'MEDIUM', 'Medium'
    HIGH = 'HIGH', 'High'
    CRITICAL = 'CRITICAL', 'Critical'


class CardStatus(models.TextChoices):
    TODO = 'TODO', 'To-Do'
    DOING = 'DOING', 'Doing'
    BLOCKED = 'BLOCKED', 'Blocked'
    DONE = 'DONE', 'Done'


class Card(models.Model):
    id = models.AutoField(primary_key=True)
    title = models.CharField(unique=True, max_length=255)
    priority = models.CharField(
        max_length=10,
        choices=CardPriority.choices,
        default=CardPriority.MEDIUM
    )
    start_date = models.DateTimeField(default=timezone.now)
    due_date = models.DateTimeField(default=get_due_date())
    description = models.TextField(default='This is a new card')
    status = models.CharField(
        max_length=10,
        choices=CardStatus.choices,
        default=CardStatus.TODO
    )
    board = models.ForeignKey(Board, related_name="cards", on_delete=models.CASCADE)
    members = models.ManyToManyField(TheUser, related_name="tasks")

    def __str__(self):
        return self.title


class Message(models.Model):
    board = models.ForeignKey(Board, related_name="messages", on_delete=models.CASCADE)
    date_sent = models.DateTimeField(auto_now_add=True, blank=True)
    sent_by = models.ForeignKey(TheUser, related_name='sent_messages', on_delete=models.CASCADE)
    content = models.TextField()

    def __str__(self):
        return f"{str(self.board)} {self.sent_by}"
 


