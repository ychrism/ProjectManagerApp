# Generated by Django 3.2.19 on 2024-10-04 16:17

import datetime
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0012_auto_20241002_1744'),
    ]

    operations = [
        migrations.AlterField(
            model_name='board',
            name='due_date',
            field=models.DateTimeField(default=datetime.datetime(2024, 12, 13, 16, 17, 26, 449871)),
        ),
        migrations.AlterField(
            model_name='card',
            name='due_date',
            field=models.DateTimeField(default=datetime.datetime(2024, 12, 13, 16, 17, 26, 450907)),
        ),
    ]
