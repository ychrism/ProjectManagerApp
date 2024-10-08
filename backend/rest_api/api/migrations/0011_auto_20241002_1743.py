# Generated by Django 3.2.19 on 2024-10-02 17:43

import datetime
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0010_auto_20240930_1937'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='message',
            name='received_by',
        ),
        migrations.AddField(
            model_name='message',
            name='board',
            field=models.ForeignKey(default=1, on_delete=django.db.models.deletion.CASCADE, related_name='messages', to='api.board'),
            preserve_default=False,
        ),
        migrations.AlterField(
            model_name='board',
            name='due_date',
            field=models.DateTimeField(default=datetime.datetime(2024, 12, 11, 17, 43, 5, 96918)),
        ),
        migrations.AlterField(
            model_name='card',
            name='due_date',
            field=models.DateTimeField(default=datetime.datetime(2024, 12, 11, 17, 43, 5, 102990)),
        ),
        migrations.AlterField(
            model_name='message',
            name='id',
            field=models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID'),
        ),
        migrations.DeleteModel(
            name='GroupMessage',
        ),
    ]
