# Generated by Django 3.2.19 on 2024-10-05 02:07

import datetime
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0013_auto_20241004_1617'),
    ]

    operations = [
        migrations.AlterField(
            model_name='board',
            name='due_date',
            field=models.DateTimeField(default=datetime.datetime(2024, 12, 14, 2, 7, 51, 240962)),
        ),
        migrations.AlterField(
            model_name='card',
            name='due_date',
            field=models.DateTimeField(default=datetime.datetime(2024, 12, 14, 2, 7, 51, 246144)),
        ),
    ]
