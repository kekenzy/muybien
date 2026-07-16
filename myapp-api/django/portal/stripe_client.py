import stripe
from django.conf import settings

stripe.api_key = settings.STRIPE_SECRET_KEY


def get_or_create_stripe_customer(customer):
    """lab.Customer に紐づくStripe顧客を取得、無ければ作成してcustomer.stripe_customer_idに保存する"""
    if customer.stripe_customer_id:
        return customer.stripe_customer_id

    stripe_customer = stripe.Customer.create(email=customer.email, name=customer.name)
    customer.stripe_customer_id = stripe_customer.id
    customer.save(update_fields=['stripe_customer_id'])
    return stripe_customer.id


def list_payment_methods(customer):
    """カード一覧を [{id, brand, last4, exp_month, exp_year, is_default}, ...] で返す"""
    if not customer.stripe_customer_id:
        return []

    stripe_customer = stripe.Customer.retrieve(customer.stripe_customer_id)
    default_pm_id = stripe_customer.invoice_settings.default_payment_method
    payment_methods = stripe.PaymentMethod.list(customer=customer.stripe_customer_id, type='card')

    return [
        {
            'id': pm.id,
            'brand': pm.card.brand,
            'last4': pm.card.last4,
            'exp_month': pm.card.exp_month,
            'exp_year': pm.card.exp_year,
            'is_default': pm.id == default_pm_id,
        }
        for pm in payment_methods.data
    ]


def payment_method_belongs_to_customer(customer, payment_method_id):
    if not customer.stripe_customer_id:
        return False
    payment_method = stripe.PaymentMethod.retrieve(payment_method_id)
    return payment_method.customer == customer.stripe_customer_id


def create_setup_intent(customer):
    stripe_customer_id = get_or_create_stripe_customer(customer)
    intent = stripe.SetupIntent.create(customer=stripe_customer_id, payment_method_types=['card'])
    return intent.client_secret


def set_default_payment_method(customer, payment_method_id):
    stripe.Customer.modify(
        customer.stripe_customer_id,
        invoice_settings={'default_payment_method': payment_method_id},
    )


def detach_payment_method(payment_method_id):
    stripe.PaymentMethod.detach(payment_method_id)
