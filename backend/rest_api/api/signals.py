from django.db.models.signals import post_save
from django.dispatch import receiver, Signal
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from .models import Message, Board


@receiver(post_save, sender=Message)
def message_post_save(sender, instance, created, **kwargs):
    if created:
        channel_layer = get_channel_layer()
        board = instance.board
        message_data = {
            'id': instance.id,
            'board': instance.board.to_dict(),
            'sent_by': instance.sent_by.to_dict(),
            'content': instance.content,
            'date_sent': instance.date_sent.isoformat()
        }
        
        # Send to all members of the board
        for member in board.members.all():
            print(f"In signals: {member.id}")
            async_to_sync(channel_layer.group_send)(
                f"user_{member.id}_latest_messages",
                {
                    "type": "latest_message_update",
                    "message": message_data
                }
            )

    