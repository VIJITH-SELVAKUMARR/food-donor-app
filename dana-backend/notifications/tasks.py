from celery import shared_task
from django.core.mail import send_mail

@shared_task
def send_donation_notification(donation_id):
    # load donation, find admin or interested organizations and notify
    pass
