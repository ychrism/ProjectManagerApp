from django.db.models.signals import post_save
from django.dispatch import receiver, Signal
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from .models import Message, Card, TheUser
import logging


logger = logging.getLogger('api')

@receiver(post_save, sender=Message)
def message_post_save(sender, instance, created, **kwargs):
    # This function is called whenever a Message instance is saved. 
    # latest_message_update in related Consumer is called went this type of message is sent by signal
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
            async_to_sync(channel_layer.group_send)(
                f"user_{member.id}_latest_messages",
                {
                    "type": "latest_message_update",
                    "message": message_data
                }
            )

         # Send to all admin users
        admin_users = TheUser.objects.filter(is_admin=True)
        for admin in admin_users:
            if admin not in board.members.all():
                async_to_sync(channel_layer.group_send)(
                f"user_{admin.id}_latest_messages",
                {
                    "type": "latest_message_update",
                    "message": message_data
                }
            )


@receiver(post_save, sender=Card)
def card_status_updated(sender, instance, created, **kwargs):
    # This function is called whenever a Message instance is saved. 
    # card_status_update in related Consumer is called went this type of message is sent by signal
    try:
        channel_layer = get_channel_layer()
        board_name = f"board_{instance.board.id}"
        
        async_to_sync(channel_layer.group_send)(
            board_name,
            {
                "type": "card_status_update",
                "message": {
                    "card_id": instance.id,
                    "new_status": instance.status,
                }
            }
        )
        logger.debug(f"Message sent successfully to group {board_name}")
    except Exception as e:
        logger.error(f"Error sending card update message: {str(e)}")