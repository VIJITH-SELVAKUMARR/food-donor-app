import logging
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Donation
from users.models import NGOVerification

logger = logging.getLogger(__name__)


@receiver(post_save, sender=Donation)
def donation_status_logger(sender, instance, created, **kwargs):
    if created:
        logger.info(f"Donation created: {instance.food_type} by {instance.donor.username} (ID: {instance.id})")
    else:
        if instance.status == "claimed" and instance.ngo:
            logger.info(f"Donation claimed: {instance.food_type} (ID: {instance.id}) by NGO {instance.ngo.username}")
        elif instance.status == "completed" and instance.recipient:
            logger.info(
                f"Donation completed: {instance.food_type} (ID: {instance.id}) "
                f"by NGO {instance.ngo.username} → delivered to {instance.recipient.username}"
            )
        elif instance.status == "expired":
            logger.info(f"Donation expired: {instance.food_type} (ID: {instance.id})")


@receiver(post_save, sender=NGOVerification)
def ngo_verification_logger(sender, instance, created, **kwargs):
    if created:
        logger.info(f"NGO verification submitted by {instance.user.username} (ID: {instance.id})")
    elif instance.verified:
        logger.info(f"NGO verified: {instance.user.username} (ID: {instance.id})")
