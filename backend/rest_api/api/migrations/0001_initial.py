# Generated by Django 3.2.19 on 2024-09-21 08:19

import datetime
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone
from django.utils.timezone import utc


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='TheUser',
            fields=[
                ('last_login', models.DateTimeField(blank=True, null=True, verbose_name='last login')),
                ('id', models.AutoField(primary_key=True, serialize=False)),
                ('first_name', models.CharField(max_length=30)),
                ('last_name', models.CharField(max_length=30)),
                ('email', models.EmailField(max_length=254, unique=True)),
                ('password', models.CharField(max_length=128)),
                ('is_admin', models.BooleanField(default=False)),
            ],
            options={
                'abstract': False,
            },
        ),
        migrations.CreateModel(
            name='Board',
            fields=[
                ('id', models.AutoField(primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=100)),
                ('start_date', models.DateTimeField(default=django.utils.timezone.now)),
                ('due_date', models.DateTimeField(default=datetime.datetime(2024, 11, 30, 8, 19, 24, 253622, tzinfo=utc))),
                ('description', models.TextField(default='This is a new board')),
                ('progress', models.FloatField(default=0)),
                ('pic', models.ImageField(blank=True, null=True, upload_to='uploads/images/')),
                ('members', models.ManyToManyField(related_name='boards', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name='Message',
            fields=[
                ('id', models.AutoField(primary_key=True, serialize=False)),
                ('date_sent', models.DateTimeField(auto_now_add=True)),
                ('content', models.TextField()),
                ('received_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='received_messages', to=settings.AUTH_USER_MODEL)),
                ('sent_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='sent_messages', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name='GroupMessage',
            fields=[
                ('id', models.AutoField(primary_key=True, serialize=False)),
                ('date_sent', models.DateTimeField(auto_now_add=True)),
                ('content', models.TextField()),
                ('board', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='group_messages', to='api.board')),
                ('sent_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='sent_group_messages', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name='Card',
            fields=[
                ('id', models.AutoField(primary_key=True, serialize=False)),
                ('title', models.CharField(max_length=255)),
                ('priority', models.CharField(choices=[('LOW', 'Low'), ('MEDIUM', 'Medium'), ('HIGH', 'High'), ('URGENT', 'Urgent')], default='MEDIUM', max_length=10)),
                ('start_date', models.DateTimeField(default=django.utils.timezone.now)),
                ('due_date', models.DateTimeField(default=datetime.datetime(2024, 11, 30, 8, 19, 24, 255146, tzinfo=utc))),
                ('description', models.TextField(default='This is a new card')),
                ('status', models.CharField(choices=[('TODO', 'To-Do'), ('DOING', 'Doing'), ('BLOCKED', 'Blocked'), ('DONE', 'Done')], default='TODO', max_length=10)),
                ('board', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='cards', to='api.board')),
                ('members', models.ManyToManyField(related_name='tasks', to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]
